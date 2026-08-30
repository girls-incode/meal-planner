class CreateIngredientAliases < ActiveRecord::Migration[8.1]
  def change
    create_table :ingredient_aliases, id: :uuid do |t|
      t.references :ingredient, null: false, type: :uuid, foreign_key: true, index: true
      t.string :alias, null: false
      t.citext :normalized_alias, null: false

      t.timestamps
    end

    add_index :ingredient_aliases, :normalized_alias, unique: true
  end
end
