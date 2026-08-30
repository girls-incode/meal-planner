class AddIngredientIdsToRecipes < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    add_column :recipes, :canonical_ingredient_ids, :uuid, array: true, null: false, default: []

    execute <<~SQL.squish
      UPDATE recipes
      SET (canonical_ingredient_ids, required_ingredient_count) = (
        SELECT COALESCE(array_agg(ingredient_id ORDER BY ingredient_id), ARRAY[]::uuid[]), COUNT(*)::integer
        FROM recipe_ingredients
        WHERE recipe_id = recipes.id
      )
    SQL

    add_index :recipes, :canonical_ingredient_ids, using: :gin, algorithm: :concurrently,
      name: :index_recipes_on_canonical_ingredient_ids_gin
    add_check_constraint :recipes, "cardinality(canonical_ingredient_ids) = required_ingredient_count",
      name: :recipes_canonical_ingredient_ids_count_matches_required, validate: false
    validate_check_constraint :recipes, name: :recipes_canonical_ingredient_ids_count_matches_required
  end

  def down
    remove_check_constraint :recipes, name: :recipes_canonical_ingredient_ids_count_matches_required
    remove_index :recipes, name: :index_recipes_on_canonical_ingredient_ids_gin
    remove_column :recipes, :canonical_ingredient_ids
  end
end
