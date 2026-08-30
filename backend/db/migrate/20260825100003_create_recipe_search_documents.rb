class CreateRecipeSearchDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :recipe_search_documents, id: false do |t|
      t.uuid :recipe_id, null: false, primary_key: true
      t.column :ingredient_ids, :uuid, array: true, null: false, default: []
      t.integer :distinct_ingredient_count, null: false, default: 0
      t.integer :total_ingredient_lines, null: false, default: 0
      t.timestamps
    end

    add_foreign_key :recipe_search_documents, :recipes
    add_index :recipe_search_documents, :ingredient_ids, using: :gin
  end
end
