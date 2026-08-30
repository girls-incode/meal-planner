module Api
  module V1
    class IngredientsController < ApplicationController
      DEFAULT_LIMIT = 20
      MAX_LIMIT = 20

      def index
        query = params.fetch(:q, "")
        raise Api::InvalidRequest, "q must be a string of at most 100 characters" unless query.is_a?(String) && query.length <= 100

        limit = bounded_integer(:limit, default: DEFAULT_LIMIT, maximum: MAX_LIMIT)
        cursor = params[:cursor].present? ? IngredientCursor.decode(params[:cursor], query:) : nil
        ingredients = Ingredient.in_recipe_catalog.search(query).order(:name, :id)
        ingredients = ingredients.where(after_cursor_sql, name: cursor.fetch("name"), id: cursor.fetch("id")) if cursor
        ingredients = ingredients.limit(limit + 1).to_a
        has_next_page = ingredients.length > limit
        ingredients = ingredients.first(limit)

        render json: {
          data: IngredientSerializer.collection_as_json(ingredients),
          nextCursor: has_next_page ? IngredientCursor.encode(ingredients.last, query:) : nil
        }
      end

      private

      def after_cursor_sql
        "ingredients.name > :name OR (ingredients.name = :name AND ingredients.id > :id)"
      end
    end
  end
end
