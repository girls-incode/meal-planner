class CreatePantries < ActiveRecord::Migration[8.1]
  def change
    create_table :pantries, id: :uuid do |t|
      t.string :session_token, null: false

      t.timestamps
    end

    add_index :pantries, :session_token, unique: true
  end
end
