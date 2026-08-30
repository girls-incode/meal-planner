class NormalizeRecipeCategories < ActiveRecord::Migration[8.1]
  def up
    create_table :categories, id: :uuid do |t|
      t.string :name, null: false

      t.timestamps
    end
    add_index :categories, :name, unique: true

    add_reference :recipes, :category, type: :uuid, foreign_key: true

    execute <<~SQL.squish
      INSERT INTO categories (name, created_at, updated_at)
      SELECT DISTINCT BTRIM(category), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
      FROM recipes
      WHERE NULLIF(BTRIM(category), '') IS NOT NULL
      ON CONFLICT (name) DO NOTHING
    SQL

    execute <<~SQL.squish
      UPDATE recipes
      SET category_id = categories.id
      FROM categories
      WHERE BTRIM(recipes.category) = categories.name
    SQL

    remove_column :recipes, :category, :string
  end

  def down
    add_column :recipes, :category, :string

    execute <<~SQL.squish
      UPDATE recipes
      SET category = categories.name
      FROM categories
      WHERE recipes.category_id = categories.id
    SQL

    remove_reference :recipes, :category, type: :uuid, foreign_key: true
    drop_table :categories
  end
end
