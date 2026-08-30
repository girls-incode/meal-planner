module Api
  module V1
    class RecipesController < ApplicationController
      before_action :require_pantry_session

      def show
        raise Api::InvalidRequest, "id must be a UUID" unless uuid?(params[:id])

        recipe = Recipe.includes(:author, :category, recipe_ingredients: :ingredient).find(params[:id])
        pantry = current_pantry
        owned_ingredient_ids = pantry.ingredients.pluck(:id)
        missing_ingredients = RecipeMatcher.missing_ingredients_by_recipe(
          recipe_ids: [ recipe.id ], pantry:
        ).fetch(recipe.id, [])

        render json: RecipeDetailSerializer.as_json(recipe, owned_ingredient_ids:, missing_ingredients:)
      end

      private
    end
  end
end
