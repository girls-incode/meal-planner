class RemoveExpiresAtFromPantryItems < ActiveRecord::Migration[8.1]
  def change
    remove_column :pantry_items, :expires_at, :datetime
  end
end
