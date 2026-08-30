class CreateUsersAndExtendPantryItems < ActiveRecord::Migration[8.1]
  def change
    create_table :users, id: :uuid do |t|
      t.string :email
      t.timestamps
    end

    add_index :users, :email, unique: true, where: "email IS NOT NULL"

    add_reference :pantry_items, :user, type: :uuid, foreign_key: true
    add_column :pantry_items, :quantity, :decimal
    add_column :pantry_items, :unit, :string
    add_column :pantry_items, :expires_at, :datetime
  end
end
