class CreateRecipes < ActiveRecord::Migration[8.1]
  def change
    create_table :recipes, id: :uuid do |t|
      t.string :title, null: false
      t.integer :prep_time_minutes
      t.integer :cook_time_minutes
      t.float :ratings
      t.string :cuisine
      t.string :category
      t.string :author
      t.string :image_url
      t.integer :required_ingredient_count, null: false, default: 0

      t.timestamps
    end

    add_index :recipes, :title
  end
end
