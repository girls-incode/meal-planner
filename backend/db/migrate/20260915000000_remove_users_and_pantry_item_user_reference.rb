class RemoveUsersAndPantryItemUserReference < ActiveRecord::Migration[8.1]
  def up
    remove_reference :pantry_items, :user, foreign_key: true
    drop_table :users
  end

  def down
    create_table :users, id: :uuid do |t|
      t.string :email
      t.timestamps
    end

    add_index :users, :email, unique: true, where: "email IS NOT NULL"
    add_reference :pantry_items, :user, type: :uuid, foreign_key: true
  end
end
