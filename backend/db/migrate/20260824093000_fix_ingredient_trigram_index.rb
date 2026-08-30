class FixIngredientTrigramIndex < ActiveRecord::Migration[8.1]
  def up
    # gin_trgm_ops cannot serve ILIKE against a citext column, so the plain
    # index added alongside it never got used — autocomplete still fell back to
    # a sequential scan. Indexing the text cast instead gives the planner
    # something it can actually match, provided the query casts too (see
    # Ingredient.search).
    remove_index :ingredients, name: "index_ingredients_on_name_trgm"
    execute <<~SQL
      CREATE INDEX index_ingredients_on_name_trgm
      ON ingredients USING gin ((name::text) gin_trgm_ops)
    SQL
  end

  def down
    remove_index :ingredients, name: "index_ingredients_on_name_trgm"
    add_index :ingredients, :name, using: :gin, opclass: :gin_trgm_ops, name: "index_ingredients_on_name_trgm"
  end
end
