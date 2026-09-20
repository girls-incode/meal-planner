class AddPantryAndCursorIndexToPantryItems < ActiveRecord::Migration[8.1]
  def change
    add_index :pantry_items, [:pantry_id, :created_at, :id], name: "index_pantry_items_on_pantry_and_cursor"
  end
end
