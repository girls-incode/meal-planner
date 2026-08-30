# typed: true
# frozen_string_literal: true

require "set"

module RecipeImport
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
      recipe_ids, recipe_ingredient_count = ActiveRecord::Base.transaction do
        recipe_ids = upsert_recipes(batch)
        recipe_ingredient_count = upsert_ingredients(batch, recipe_ids)
        persist_issues(batch, recipe_ids)
        [ recipe_ids, recipe_ingredient_count ]
      end
      recipe_ingredient_count
    end

    private

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

    sig { params(batch: T.untyped, recipe_ids: T.untyped).returns(Integer) }
    def upsert_ingredients(batch, recipe_ids)
      rows_by_recipe_id = recipe_ids.values.index_with { [] }
      batch.each do |document|
        recipe_id = recipe_ids[recipe_key(document)]
        next if recipe_id.blank?

        seen = Set.new
        rows_by_recipe_id[recipe_id] = document[:lines].flat_map { |line| rows_for(line, recipe_id, seen) }
      end
      RecipeIngredients::Replace.call(rows_by_recipe_id:)
      rows_by_recipe_id.values.sum(&:size)
    end

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

    sig { params(batch: T.untyped, recipe_ids: T.untyped).void }
    def persist_issues(batch, recipe_ids)
      rows = batch.flat_map do |document|
        recipe_id = recipe_ids[recipe_key(document)]
        next [] if recipe_id.blank?

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
