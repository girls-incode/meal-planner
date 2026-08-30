class CreatePantryItems < ActiveRecord::Migration[8.1]
  def change
    create_table :pantry_items, id: :uuid do |t|
      t.references :pantry, null: false, type: :uuid, foreign_key: true
      t.references :ingredient, null: false, type: :uuid, foreign_key: true

      t.timestamps
    end

    add_index :pantry_items, %i[pantry_id ingredient_id], unique: true,
      name: "index_pantry_items_on_pantry_and_ingredient"
  end
end
