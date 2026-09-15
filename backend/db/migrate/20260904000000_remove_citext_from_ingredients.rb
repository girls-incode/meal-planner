class RemoveCitextFromIngredients < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      UPDATE ingredients
      SET name = lower(name::text)
      WHERE name::text <> lower(name::text)
    SQL

    change_column :ingredients, :name, :string, null: false
    add_check_constraint :ingredients, "name = lower(name)", name: "ingredients_name_is_lowercase"
    disable_extension "citext"
  end

  def down
    enable_extension "citext"
    remove_check_constraint :ingredients, name: "ingredients_name_is_lowercase"
    change_column :ingredients, :name, :citext, null: false
  end
end
