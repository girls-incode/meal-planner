# typed: true
# frozen_string_literal: true

# Finds recipes that can be made from a given set of ingredients, ranking
# recipes with 100% of their ingredients ("complete matches") above recipes
# missing a few ("partial matches"). Runs as two separate SQL queries:
#
# - complete_matches: recipes where canonical_ingredient_ids is fully
#   contained in the searched ingredients, via a GIN containment query.
# - partial_matches: recipes missing between 1 and max_missing ingredients,
#   via a normalized join that counts how many of the searched ingredients
#   each recipe actually uses.
#
# #call runs complete_matches first and only queries partial_matches if the
# complete page isn't already full, then concatenates the two Ruby arrays
# into one page of results. Because complete and partial matches are sorted
# by different columns (partial matches also rank by match percentage),
# every row is tagged with a match_phase ("full" or "partial") so that,
# once the two arrays are combined, RecipeMatchCursor can tell which sort
# order to resume from when the client asks for the next page.
class RecipeMatcher
  extend T::Sig

  DEFAULT_MAX_MISSING = 4
  DEFAULT_LIMIT = 20

  sig do
    params(
      ingredient_ids: T::Array[String], max_missing: Integer, limit: Integer,
      cursor: T.nilable(String)
    ).void
  end
  def initialize(ingredient_ids:, max_missing: DEFAULT_MAX_MISSING, limit: DEFAULT_LIMIT, cursor: nil)
    raise ArgumentError, "ingredient_ids must not be empty" if ingredient_ids.empty?

    @ingredient_ids = ingredient_ids
    @max_missing = max_missing
    @limit = limit
    @cursor = cursor
  end

  # Loads at most limit + 1 recipes (the extra row lets the caller detect
  # whether there's a next page without a separate COUNT query). Complete
  # matches are fetched first; the partial-match query only runs if there's
  # still room left on the page, and only requests as many rows as needed to
  # fill it.
  sig { returns(T::Array[Recipe]) }
  def call
    cursor = decoded_cursor
    # A cursor already in the partial phase means we've moved past all
    # complete matches on a previous page, so there's no need to re-check them.
    return partial_matches(cursor).to_a if cursor&.fetch("phase") == RecipeMatchCursor::PARTIAL_PHASE

    complete = complete_matches(cursor).to_a
    return complete if complete.size > @limit

    complete + partial_matches(nil, limit: @limit + 1 - complete.size).to_a
  end

  # For each of the given recipes, returns the ingredients it still needs
  # that aren't in the pantry (or, if pantry is nil, aren't in the given
  # ingredient_ids). Called after #call/RecipesController#show have already
  # picked which recipes to show, to fill in their "missing ingredients"
  # list for the API response.
  #
  # Runs one query for every recipe passed in, rather than one query per
  # recipe, to avoid N+1 queries when rendering a whole page of results.
  #
  # Needs real Ingredient rows (id and name), which #call's SQL doesn't
  # return — #call only counts how many ingredients matched, it doesn't
  # fetch which ones are missing.
  sig do
    params(
      recipe_ids: T::Array[String], pantry: T.nilable(Pantry),
      ingredient_ids: T.nilable(T::Array[String])
    ).returns(T::Hash[String, T::Array[Ingredient]])
  end
  def self.missing_ingredients_by_recipe(recipe_ids:, pantry: nil, ingredient_ids: nil)
    return {} if recipe_ids.empty?

    rows = RecipeIngredient
      .joins(:ingredient)
      .where(recipe_id: recipe_ids)
      .where.not(ingredient_id: available_ingredient_ids(pantry:, ingredient_ids:))
      .order(:recipe_id, "ingredients.name", "ingredients.id")
      .pluck(:recipe_id, "ingredients.id", "ingredients.name")

    rows.each_with_object(Hash.new { |h, k| h[k] = [] }) do |(recipe_id, ingredient_id, name), acc|
      acc[recipe_id] << Ingredient.new(id: ingredient_id, name: name)
    end
  end

  sig do
    params(pantry: T.nilable(Pantry), ingredient_ids: T.nilable(T::Array[String]))
      .returns(T.untyped)
  end
  def self.available_ingredient_ids(pantry:, ingredient_ids:)
    return pantry.ingredients.select(:id) if pantry

    ingredient_ids
  end

  private

  sig { returns(T.nilable(T::Hash[String, T.untyped])) }
  def decoded_cursor
    return nil if @cursor.blank?

    cursor = RecipeMatchCursor.decode(
      @cursor, ingredient_ids: @ingredient_ids, max_missing: @max_missing
    )
    return cursor if RecipeMatchCursor::PHASES.include?(cursor["phase"])

    raise Cursor::InvalidCursor, "cursor is invalid"
  end

  # canonical_ingredient_ids is a denormalized copy of each recipe's
  # ingredient IDs, stored right on the recipe row and GIN-indexed, so "is
  # every ingredient this recipe needs in the search set" (<@) can be
  # answered with one fast indexed lookup instead of joining
  # recipe_ingredients per recipe.
  sig { params(cursor: T.nilable(T::Hash[String, T.untyped])).returns(T.untyped) }
  def complete_matches(cursor)
    scope = Recipe
      .where("recipes.canonical_ingredient_ids <@ #{ingredient_ids_array_sql}")
      .where("recipes.required_ingredient_count > 0")
      .select(*[
        "recipes.*",
        "recipes.required_ingredient_count AS matched_ingredients",
        "0 AS missing_count",
        "100.0 AS match_percentage",
        "'full' AS match_phase"
      ])
      .order(Arel.sql(rank_order_sql))
      .limit(@limit + 1)
    cursor ? scope.where(RecipeMatchCursor.full_after_sql(cursor:)) : scope
  end

  sig do
    params(cursor: T.nilable(T::Hash[String, T.untyped]), limit: Integer)
      .returns(T.untyped)
  end
  def partial_matches(cursor, limit: @limit + 1)
    scope = Recipe
      .from(Arel.sql("(#{partial_match_projection_sql}) AS recipes"))
      .where("recipes.missing_count BETWEEN 1 AND ?", @max_missing)
      .order(Arel.sql(partial_order_sql))
      .limit(limit)
    cursor ? scope.where(RecipeMatchCursor.partial_after_sql(cursor:)) : scope
  end

  sig { returns(String) }
  def matched_join_sql
    <<~SQL.squish
      INNER JOIN (
        SELECT ri.recipe_id, COUNT(*) AS matched_ingredients
        FROM recipe_ingredients ri
        WHERE ri.ingredient_id = ANY(#{ingredient_ids_array_sql})
        GROUP BY ri.recipe_id
      ) matched ON matched.recipe_id = recipes.id
    SQL
  end

  # Builds this SQL as a subquery, rather than inline in partial_matches,
  # so match_percentage and missing_count can be computed once here and
  # then just referenced by name in the outer WHERE/ORDER BY/LIMIT. Tags
  # every row 'partial'.
  sig { returns(String) }
  def partial_match_projection_sql
    <<~SQL.squish
      SELECT recipes.*,
             matched.matched_ingredients AS matched_ingredients,
             (recipes.required_ingredient_count - matched.matched_ingredients) AS missing_count,
             #{match_percentage_sql} AS match_percentage,
             'partial' AS match_phase
      FROM recipes
      #{matched_join_sql}
    SQL
  end

  # Tiebreak order shared by both phases, used whenever recipes are
  # otherwise equally good matches: highest rating first, then fewest
  # required ingredients, then id (always unique, so this guarantees a
  # fully deterministic order with no ties left).
  #
  # Ratings is negated so all three columns sort ascending — this lets
  # RecipeMatchCursor's cursor logic compare them as one tuple.
  # If this order changes, then update RecipeMatchCursor#rank_after_sql to match,
  # or pagination will silently skip or repeat rows.
  sig { returns(String) }
  def rank_order_sql
    "-COALESCE(recipes.ratings, #{RecipeMatchCursor::RATINGS_FLOOR}) ASC, " \
    "recipes.required_ingredient_count ASC, recipes.id ASC"
  end

  sig { returns(String) }
  def partial_order_sql
    "recipes.match_percentage DESC, recipes.missing_count ASC, #{rank_order_sql}"
  end

  sig { returns(String) }
  def match_percentage_sql
    "ROUND(matched.matched_ingredients::numeric / NULLIF(recipes.required_ingredient_count, 0) * 100, 1)"
  end

  # Builds a Postgres uuid[] array literal, e.g. ARRAY['id1', 'id2']::uuid[],
  # for the <@ and = ANY(...) checks above. Rails' where(column: array)
  # sugar can't produce this literal form, so it's built by hand; .quote
  # escapes each id to keep this safe from SQL injection.
  sig { returns(String) }
  def ingredient_ids_array_sql
    ids = @ingredient_ids.map { |id| ActiveRecord::Base.connection.quote(id) }.join(", ")
    "ARRAY[#{ids}]::uuid[]"
  end
end
