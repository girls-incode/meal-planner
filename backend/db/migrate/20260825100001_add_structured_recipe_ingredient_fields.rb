class AddStructuredRecipeIngredientFields < ActiveRecord::Migration[8.1]
  def change
    add_column :recipe_ingredients, :preparation, :text
    add_column :recipe_ingredients, :qualifier, :text
  end
end
