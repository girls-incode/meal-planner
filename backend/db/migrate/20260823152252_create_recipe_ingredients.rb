class CreateRecipeIngredients < ActiveRecord::Migration[8.1]
  def change
    create_table :recipe_ingredients, id: :uuid do |t|
      t.references :recipe, null: false, type: :uuid, foreign_key: true
      t.references :ingredient, null: false, type: :uuid, foreign_key: true
      t.string :raw_text, null: false
      t.decimal :quantity
      t.string :unit

      t.timestamps
    end

    # Serves "given a recipe, what are its ingredients" (recipe detail,
    # dedup on seed) and prevents duplicate rows.
    add_index :recipe_ingredients, %i[recipe_id ingredient_id], unique: true,
      name: "index_recipe_ingredients_on_recipe_and_ingredient"

    # Serves the opposite traversal — "given an ingredient, which recipes
    # use it" — which is the direction RecipeMatcher actually needs, since
    # it starts from the user's small pantry set rather than the full
    # recipe catalog.
    add_index :recipe_ingredients, %i[ingredient_id recipe_id],
      name: "index_recipe_ingredients_on_ingredient_and_recipe"
  end
end
