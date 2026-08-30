module Api
  module V1
    class RecipeMatchesController < ApplicationController
      def create
        max_missing = bounded_integer(:maxMissing, default: RecipeMatcher::DEFAULT_MAX_MISSING, minimum: 0, maximum: 100)
        limit = bounded_integer(:limit, default: RecipeMatcher::DEFAULT_LIMIT, maximum: 100)
        raise Api::InvalidRequest, "page is not supported; use cursor" if params.key?(:page)

        ingredient_ids = selected_ingredient_ids
        category_id = selected_category_id
        matcher = RecipeMatcher.new(ingredient_ids:, category_id:, max_missing:, limit:, cursor: params[:cursor])
        recipes = matcher.call
        has_next_page = recipes.length > limit
        recipes = recipes.first(limit)
        ActiveRecord::Associations::Preloader.new(records: recipes, associations: %i[author category]).call
        missing_by_recipe = RecipeMatcher.missing_ingredients_by_recipe(recipe_ids: recipes.map(&:id), ingredient_ids:)

        next_cursor = has_next_page ? RecipeMatchCursor.encode(
          recipe: recipes.last, ingredient_ids:, max_missing:, category_id:
        ) : nil
        render json: {
          data: RecipeMatchSerializer.collection_as_json(recipes, missing_by_recipe:),
          nextCursor: next_cursor
        }
      end

      private

      def selected_ingredient_ids
        ingredient_ids = params[:ingredients]
        unless ingredient_ids.is_a?(Array) && ingredient_ids.any? && ingredient_ids.size <= 100
          raise Api::InvalidRequest, "ingredients must be a non-empty array of at most 100 ingredient IDs"
        end
        ingredient_ids = ingredient_ids.uniq

        unless ingredient_ids.all? { |v| uuid?(v) }
          raise Api::InvalidRequest, "ingredients must contain UUIDs"
        end

        found_count = Ingredient.where(id: ingredient_ids).count
        raise Api::InvalidRequest, "ingredients contains unknown ingredients" unless found_count == ingredient_ids.size

        ingredient_ids
      end

      def selected_category_id
        return nil unless params.key?(:categoryId)

        value = params[:categoryId]
        unless uuid?(value)
          raise Api::InvalidRequest, "categoryId must be a UUID"
        end
        raise Api::InvalidRequest, "categoryId is unknown" unless Category.exists?(id: value)

        value
      end
    end
  end
end
