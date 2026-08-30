class CreateImportTrackingTables < ActiveRecord::Migration[8.1]
  def change
    create_table :import_runs, id: :uuid do |t|
      t.string :source_url, null: false
      t.string :source_fingerprint
      t.string :parser_version, null: false
      t.string :status, null: false
      t.datetime :started_at, null: false
      t.datetime :finished_at
      t.integer :recipes_seen, null: false, default: 0
      t.integer :recipes_imported, null: false, default: 0
      t.integer :ingredients_created, null: false, default: 0
      t.integer :ingredients_normalized, null: false, default: 0
      t.integer :parse_errors, null: false, default: 0
      t.text :error_message
      t.timestamps
    end

    add_index :import_runs, :source_fingerprint
    add_index :import_runs, :status

    create_table :ingredient_parse_errors, id: :uuid do |t|
      t.uuid :recipe_id
      t.uuid :import_run_id, null: false
      t.string :original_text, null: false
      t.string :parser_version, null: false
      t.text :error, null: false
      t.timestamps
    end

    add_foreign_key :ingredient_parse_errors, :recipes
    add_foreign_key :ingredient_parse_errors, :import_runs
    add_index :ingredient_parse_errors, :recipe_id
    add_index :ingredient_parse_errors, :import_run_id
  end
end
