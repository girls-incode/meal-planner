# typed: true
# frozen_string_literal: true

# The only write boundary for a recipe's canonical ingredient projection.
# Keeping recipe_ingredients, recipes.canonical_ingredient_ids, and the stored count in
# one transaction makes the GIN-backed full-match query safe for imports and
# future user-authored recipes alike.
module RecipeIngredients
  class Replace
    extend T::Sig

    class DuplicateIngredient < ArgumentError; end

    sig { params(rows_by_recipe_id: T::Hash[String, T::Array[T::Hash[Symbol, T.untyped]]]).void }
    def self.call(rows_by_recipe_id:)
      new(rows_by_recipe_id:).call
    end

    sig { params(rows_by_recipe_id: T::Hash[String, T::Array[T::Hash[Symbol, T.untyped]]]).void }
    def initialize(rows_by_recipe_id:)
      @rows_by_recipe_id = rows_by_recipe_id
    end

    sig { void }
    def call
      return if @rows_by_recipe_id.empty?

      recipe_ids = @rows_by_recipe_id.keys.sort
      ingredient_ids_by_recipe_id = canonical_ids_by_recipe_id

      Recipe.transaction do
        locked_recipes = Recipe.where(id: recipe_ids).order(:id).lock.select(:id, :title, :created_at).to_a
        locked_ids = locked_recipes.map(&:id)
        raise ActiveRecord::RecordNotFound, "recipes to replace were not found" unless locked_ids == recipe_ids

        RecipeIngredient.where(recipe_id: recipe_ids).delete_all
        RecipeIngredient.insert_all(ingredient_rows, record_timestamps: true) unless ingredient_rows.empty?
        Recipe.upsert_all(recipe_updates(locked_recipes, ingredient_ids_by_recipe_id), unique_by: :id,
          update_only: %i[canonical_ingredient_ids required_ingredient_count updated_at], record_timestamps: false)
      end
    end

    private

    sig { returns(T::Hash[String, T::Array[String]]) }
    def canonical_ids_by_recipe_id
      @rows_by_recipe_id.each_with_object({}) do |(recipe_id, rows), result|
        row_recipe_ids = rows.map { |row| T.cast(row.fetch(:recipe_id), String) }.uniq
        raise ArgumentError, "recipe ingredient row belongs to another recipe" unless row_recipe_ids.empty? || row_recipe_ids == [ recipe_id ]

        ingredient_ids = rows.map { |row| T.cast(row.fetch(:ingredient_id), String) }
        raise DuplicateIngredient, "recipe ingredients must contain unique canonical ingredient IDs" if ingredient_ids.uniq.size != ingredient_ids.size

        result[recipe_id] = ingredient_ids.sort
      end
    end

    sig { returns(T::Array[T::Hash[Symbol, T.untyped]]) }
    def ingredient_rows
      @rows_by_recipe_id.values.flatten
    end

    sig do
      params(locked_recipes: T::Array[Recipe], ingredient_ids_by_recipe_id: T::Hash[String, T::Array[String]])
        .returns(T::Array[T::Hash[Symbol, T.untyped]])
    end
    def recipe_updates(locked_recipes, ingredient_ids_by_recipe_id)
      now = Time.current
      locked_recipes.map do |recipe|
        ingredient_ids = ingredient_ids_by_recipe_id.fetch(recipe.id)
        {
          id: recipe.id,
          title: recipe.title,
          canonical_ingredient_ids: ingredient_ids,
          required_ingredient_count: ingredient_ids.size,
          created_at: recipe.created_at,
          updated_at: now
        }
      end
    end
  end
end
