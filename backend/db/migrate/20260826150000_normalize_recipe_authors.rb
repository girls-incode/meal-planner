class NormalizeRecipeAuthors < ActiveRecord::Migration[8.1]
  def up
    create_table :authors, id: :uuid do |t|
      t.string :name, null: false

      t.timestamps
    end
    add_index :authors, :name, unique: true

    add_reference :recipes, :author, type: :uuid, foreign_key: true

    execute <<~SQL.squish
      INSERT INTO authors (name, created_at, updated_at)
      SELECT DISTINCT BTRIM(author), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
      FROM recipes
      WHERE NULLIF(BTRIM(author), '') IS NOT NULL
      ON CONFLICT (name) DO NOTHING
    SQL

    execute <<~SQL.squish
      UPDATE recipes
      SET author_id = authors.id
      FROM authors
      WHERE BTRIM(recipes.author) = authors.name
    SQL

    remove_index :recipes, name: :index_recipes_on_title_and_author
    add_index :recipes, %i[title author_id], unique: true, nulls_not_distinct: true,
      name: :index_recipes_on_title_and_author_id
    remove_column :recipes, :author, :string
  end

  def down
    add_column :recipes, :author, :string

    execute <<~SQL.squish
      UPDATE recipes
      SET author = authors.name
      FROM authors
      WHERE recipes.author_id = authors.id
    SQL

    remove_index :recipes, name: :index_recipes_on_title_and_author_id
    add_index :recipes, %i[title author], unique: true, nulls_not_distinct: true,
      name: :index_recipes_on_title_and_author
    remove_reference :recipes, :author, type: :uuid, foreign_key: true
    drop_table :authors
  end
end
