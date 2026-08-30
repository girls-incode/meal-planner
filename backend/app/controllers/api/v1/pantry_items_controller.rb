module Api
  module V1
    class PantryItemsController < ApplicationController
      before_action :require_pantry_session

      DEFAULT_LIMIT = 20
      MAX_LIMIT = 100

      def index
        limit = bounded_integer(:limit, default: DEFAULT_LIMIT, maximum: MAX_LIMIT)
        pantry = current_pantry
        cursor = params[:cursor].present? ? PantryItemCursor.decode(params[:cursor], pantry_id: pantry.id) : nil
        items = pantry.pantry_items.includes(:ingredient).order(:created_at, :id)
        items = items.where(after_cursor_sql, created_at: cursor.fetch("created_at"), id: cursor.fetch("id")) if cursor
        items = items.limit(limit + 1).to_a
        has_next_page = items.length > limit
        items = items.first(limit)

        render json: {
          data: PantryItemSerializer.collection_as_json(items),
          nextCursor: has_next_page ? PantryItemCursor.encode(items.last, pantry_id: pantry.id) : nil
        }
      end

      def create
        ingredient_id = params[:ingredientId]
        raise Api::InvalidRequest, "ingredientId must be a UUID" unless uuid?(ingredient_id)
        raise Api::InvalidRequest, "ingredientId is unknown" unless Ingredient.exists?(id: ingredient_id)

        pantry_item = PantryItems::Create.call(pantry: current_pantry, ingredient_id:)
        response.set_header("Location", "/api/v1/pantry-items/#{pantry_item.id}")
        render json: PantryItemSerializer.as_json(pantry_item), status: :created
      end

      def destroy
        raise Api::InvalidRequest, "id must be a UUID" unless uuid?(params[:id])

        PantryItems::Destroy.call(pantry: current_pantry, pantry_item_id: params[:id])
        head :no_content
      end

      private

      def after_cursor_sql
        <<~SQL.squish
          pantry_items.created_at > :created_at OR
          (pantry_items.created_at = :created_at AND pantry_items.id > :id)
        SQL
      end
    end
  end
end
