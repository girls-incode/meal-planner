class AddImportAndSearchIndexes < ActiveRecord::Migration[8.1]
  def change
    # Gives the importer a conflict target so recipes can be bulk-upserted in
    # one statement instead of being looked up one at a time. nulls_not_distinct
    # matters because author is nullable and Postgres otherwise treats every
    # NULL author as a distinct row, which would let re-imports duplicate them.
    add_index :recipes, [ :title, :author ],
      unique: true, nulls_not_distinct: true, name: "index_recipes_on_title_and_author"
    remove_index :recipes, :title, name: "index_recipes_on_title"

    # Ingredient autocomplete runs ILIKE '%q%' on every keystroke, which a
    # btree index cannot serve. A trigram GIN index can.
    enable_extension "pg_trgm"
    add_index :ingredients, :name, using: :gin, opclass: :gin_trgm_ops, name: "index_ingredients_on_name_trgm"
  end
end
