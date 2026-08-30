# typed: true
# frozen_string_literal: true

# Returns complete matches through the GIN-backed recipe projection before
# falling back to partial matches through the normalized, ingredient-leading
# index. Both paths preserve the API's existing ranking: 100% matches first.
class RecipeMatcher
  extend T::Sig

  DEFAULT_MAX_MISSING = 4
  DEFAULT_LIMIT = 20

  sig do
    params(
      ingredient_ids: T::Array[String], max_missing: Integer, limit: Integer,
      cursor: T.nilable(String), category_id: T.nilable(String)
    ).void
  end
  def initialize(ingredient_ids:, max_missing: DEFAULT_MAX_MISSING, limit: DEFAULT_LIMIT, cursor: nil, category_id: nil)
    raise ArgumentError, "ingredient_ids must not be empty" if ingredient_ids.empty?

    @ingredient_ids = ingredient_ids.uniq.sort
    @max_missing = max_missing
    @limit = limit
    @cursor = cursor
    @category_id = category_id
  end

  # Loads at most limit + 1 recipes. Complete matches use a GIN containment
  # query; the normalized partial query runs only if the complete-match phase
  # leaves room on the page.
  sig { returns(T::Array[Recipe]) }
  def call
    cursor = decoded_cursor
    return partial_matches(cursor).to_a if cursor && cursor.fetch("phase") == RecipeMatchCursor::PARTIAL_PHASE

    complete = complete_matches(cursor).to_a
    return complete if complete.size > @limit

    complete + partial_matches(nil, limit: @limit + 1 - complete.size).to_a
  end

  # Batched follow-up for detail and match responses. This remains normalized:
  # it needs the actual Ingredient records, not only the matching projection.
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
      .where.not(ingredient_id: available_ids_relation(pantry:, ingredient_ids:))
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
  def self.available_ids_relation(pantry:, ingredient_ids:)
    return pantry.ingredients.select(:id) if pantry

    Ingredient.where(id: ingredient_ids)
  end

  private

  sig { returns(T.nilable(T::Hash[String, T.untyped])) }
  def decoded_cursor
    return nil if @cursor.blank?

    cursor = RecipeMatchCursor.decode(
      @cursor, ingredient_ids: @ingredient_ids, max_missing: @max_missing, category_id: @category_id
    )
    return cursor if RecipeMatchCursor::PHASES.include?(cursor["phase"])

    raise Cursor::InvalidCursor, "cursor is invalid"
  end

  sig { params(cursor: T.nilable(T::Hash[String, T.untyped])).returns(T.untyped) }
  def complete_matches(cursor)
    scope = Recipe
      .where("recipes.canonical_ingredient_ids <@ ?", @ingredient_ids)
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
    scope = apply_category(scope)
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
    scope = apply_category(scope)
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

  # Project the match metrics once so the outer query can filter, order, and
  # paginate using their names instead of restating the calculations.
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

  # Tiebreak order shared by both phases: ratings, then required_ingredient_
  # count, then id (the final, always-unique tiebreak). Mirrors
  # RecipeMatchCursor's rank_after_sql row-comparison tuple exactly: ratings
  # is coalesced to RecipeMatchCursor::RATINGS_FLOOR and negated so it shares
  # a single ascending sort with the other two columns, keeping this ORDER
  # BY and the cursor's WHERE tie-break impossible to drift apart.
  sig { returns(String) }
  def rank_order_sql
    "-COALESCE(recipes.ratings, #{RecipeMatchCursor::RATINGS_FLOOR}) ASC, " \
    "recipes.required_ingredient_count ASC, recipes.id ASC"
  end

  sig { params(scope: T.untyped).returns(T.untyped) }
  def apply_category(scope)
    @category_id ? scope.where(category_id: @category_id) : scope
  end

  sig { returns(String) }
  def partial_order_sql
    "recipes.match_percentage DESC, recipes.missing_count ASC, #{rank_order_sql}"
  end

  sig { returns(String) }
  def match_percentage_sql
    "ROUND(matched.matched_ingredients::numeric / NULLIF(recipes.required_ingredient_count, 0) * 100, 1)"
  end

  sig { returns(String) }
  def ingredient_ids_array_sql
    ids = @ingredient_ids.map { |id| ActiveRecord::Base.connection.quote(id) }.join(", ")
    "ARRAY[#{ids}]::uuid[]"
  end
end
