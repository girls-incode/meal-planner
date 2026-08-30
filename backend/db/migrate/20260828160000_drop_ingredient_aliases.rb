class DropIngredientAliases < ActiveRecord::Migration[8.1]
  def change
    drop_table :ingredient_aliases, id: :uuid do |t|
      t.references :ingredient, null: false, type: :uuid, foreign_key: true, index: true
      t.string :alias, null: false
      t.citext :normalized_alias, null: false, index: { unique: true }
      t.timestamps
    end
  end
end
