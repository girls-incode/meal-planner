module Api
  module V1
    class CategoriesController < ApplicationController
      DEFAULT_LIMIT = 20
      MAX_LIMIT = 100

      def index
        limit = bounded_integer(:limit, default: DEFAULT_LIMIT, maximum: MAX_LIMIT)
        cursor = params[:cursor].present? ? CategoryCursor.decode(params[:cursor]) : nil
        categories = Category.in_recipe_catalog.order(:name, :id)
        categories = categories.where(after_cursor_sql, name: cursor.fetch("name"), id: cursor.fetch("id")) if cursor
        categories = categories.limit(limit + 1).to_a
        has_next_page = categories.size > limit
        categories = categories.first(limit)

        render json: {
          data: CategorySerializer.collection_as_json(categories),
          nextCursor: has_next_page ? CategoryCursor.encode(categories.last) : nil
        }
      end

      private

      def after_cursor_sql
        "categories.name > :name OR (categories.name = :name AND categories.id > :id)"
      end
    end
  end
end
