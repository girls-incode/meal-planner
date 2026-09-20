# typed: true
# frozen_string_literal: true

require "set"

module RecipeImport
  # Persists one batch of parsed recipe documents (Importer's pass 2) in a single
  # transaction: upserts recipes, replaces their ingredients via RecipeIngredients::Replace,
  # and records any parse issues, using catalogs of ingredients/categories/authors/splits
  # already resolved by Importer during pass 1.
  class BatchWriter
    extend T::Sig

    sig do
      params(catalog: T.untyped, categories: T.untyped, authors: T.untyped,
        splits: T.untyped, import_run: ImportRun, parser_version: String).void
    end
    def initialize(catalog:, categories:, authors:, splits:, import_run:, parser_version:)
      @catalog, @categories, @authors, @splits, @import_run, @parser_version = catalog, categories, authors, splits, import_run, parser_version
    end

    sig { params(batch: T.untyped).returns(Integer) }
    def call(batch)
      ActiveRecord::Base.transaction do
        recipe_ids = upsert_recipes(batch)
        documents = batch.filter_map do |document|
          recipe_id = recipe_ids[recipe_key(document)]
          [ document, recipe_id ] if recipe_id.present?
        end

        persist_issues(documents)
        upsert_ingredients(documents, recipe_ids.values)
      end
    end

    private

    # Bulk upserts recipes on (title, author_id). upsert_all skips Active Record
    # callbacks, so record_timestamps: true is needed to set created_at/updated_at, and
    # `returning` is needed to get each row's id back at all. to_h then turns those
    # returned rows into the { [title, author_id] => id } lookup other methods use to
    # find a document's recipe_id via recipe_key.
    sig { params(batch: T.untyped).returns(T.untyped) }
    def upsert_recipes(batch)
      rows = batch.map do |document|
        document[:attributes].merge(
          category_id: @categories[document[:category_name]], author_id: @authors[document[:author_name]]
        )
      end
      Recipe.upsert_all(rows, unique_by: :index_recipes_on_title_and_author_id,
        returning: %w[id title author_id], record_timestamps: true).to_h do |row|
          [ [ row["title"], row["author_id"] ], row["id"] ]
        end
    end

    # Builds each batch recipe's full recipe_ingredients row set and replaces it via
    # RecipeIngredients::Replace, which deletes and reinserts based on what's present here.
    # Every recipe_id is pre-seeded with [] so a recipe whose lines all failed to resolve
    # still gets its stale ingredients cleared, rather than being skipped and left with
    # ingredients from a previous import.
    sig { params(documents: T.untyped, recipe_ids: T.untyped).returns(Integer) }
    def upsert_ingredients(documents, recipe_ids)
      rows_by_recipe_id = recipe_ids.index_with { [] }
      documents.each do |document, recipe_id|
        seen = Set.new
        rows_by_recipe_id[recipe_id] = document[:lines].flat_map { |line| rows_for(line, recipe_id, seen) }
      end
      # The one place allowed to write recipe_ingredients: deletes each recipe's old rows,
      # inserts the new ones, and updates the recipe's cached ingredient count/ID list to match.
      RecipeIngredients::Replace.call(rows_by_recipe_id:)
      rows_by_recipe_id.values.sum(&:size)
    end

    # Turns one parsed ingredient line into zero or more recipe_ingredients rows: expands
    # compound splits (e.g. "salt and pepper" -> salt + pepper), drops names that don't
    # resolve to a catalog ingredient, and skips ingredients already seen for this recipe.
    # quantity/unit/preparation/qualifier are only kept when the line wasn't split, since a
    # compound line can't unambiguously assign one shared quantity/unit to each half.
    sig { params(line: T.untyped, recipe_id: String, seen: T.untyped).returns(T.untyped) }
    def rows_for(line, recipe_id, seen)
      names = @splits.fetch(line[:name], [ line[:name] ])
      names.filter_map do |name|
        ingredient_id = @catalog[name]
        next if ingredient_id.blank? || !seen.add?(ingredient_id)

        { recipe_id:, ingredient_id:, raw_text: line[:raw_text],
          quantity: (line[:quantity] if names.one?), unit: (line[:unit] if names.one?),
          preparation: (line[:preparation] if names.one?), qualifier: (line[:qualifier] if names.one?) }
      end
    end

    sig { params(documents: T.untyped).void }
    def persist_issues(documents)
      rows = documents.flat_map do |document, recipe_id|
        document[:issues].map do |issue|
          { recipe_id:, import_run_id: @import_run.id, original_text: issue[:original_text],
            parser_version: @parser_version, error: issue[:error], created_at: Time.current, updated_at: Time.current }
        end
      end
      IngredientParseError.insert_all(rows) unless rows.empty?
    end

    sig { params(document: T.untyped).returns(T::Array[T.untyped]) }
    def recipe_key(document)
      [ document[:attributes][:title], @authors[document[:author_name]] ]
    end
  end
end
