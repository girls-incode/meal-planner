class CreateIngredients < ActiveRecord::Migration[8.1]
  def change
    create_table :ingredients, id: :uuid do |t|
      t.citext :name, null: false

      t.timestamps
    end

    add_index :ingredients, :name, unique: true
  end
end
