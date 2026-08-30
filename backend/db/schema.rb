# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_08_29_120000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "citext"
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"

  create_table "authors", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_authors_on_name", unique: true
  end

  create_table "categories", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_categories_on_name", unique: true
  end

  create_table "import_runs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error_message"
    t.datetime "finished_at"
    t.integer "ingredients_created", default: 0, null: false
    t.integer "ingredients_normalized", default: 0, null: false
    t.integer "parse_errors", default: 0, null: false
    t.string "parser_version", null: false
    t.integer "recipes_imported", default: 0, null: false
    t.integer "recipes_seen", default: 0, null: false
    t.string "source_fingerprint"
    t.string "source_url", null: false
    t.datetime "started_at", null: false
    t.string "status", null: false
    t.datetime "updated_at", null: false
    t.index ["source_fingerprint"], name: "index_import_runs_on_source_fingerprint"
    t.index ["status"], name: "index_import_runs_on_status"
  end

  create_table "ingredient_parse_errors", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error", null: false
    t.uuid "import_run_id", null: false
    t.string "original_text", null: false
    t.string "parser_version", null: false
    t.uuid "recipe_id"
    t.datetime "updated_at", null: false
    t.index ["import_run_id"], name: "index_ingredient_parse_errors_on_import_run_id"
    t.index ["recipe_id"], name: "index_ingredient_parse_errors_on_recipe_id"
  end

  create_table "ingredients", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.citext "name", null: false
    t.datetime "updated_at", null: false
    t.index "((name)::text) gin_trgm_ops", name: "index_ingredients_on_name_trgm", using: :gin
    t.index ["name"], name: "index_ingredients_on_name", unique: true
  end

  create_table "pantries", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "session_token", null: false
    t.datetime "updated_at", null: false
    t.index ["session_token"], name: "index_pantries_on_session_token", unique: true
  end

  create_table "pantry_items", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.uuid "ingredient_id", null: false
    t.uuid "pantry_id", null: false
    t.decimal "quantity"
    t.string "unit"
    t.datetime "updated_at", null: false
    t.uuid "user_id"
    t.index ["ingredient_id"], name: "index_pantry_items_on_ingredient_id"
    t.index ["pantry_id", "ingredient_id"], name: "index_pantry_items_on_pantry_and_ingredient", unique: true
    t.index ["pantry_id"], name: "index_pantry_items_on_pantry_id"
    t.index ["user_id"], name: "index_pantry_items_on_user_id"
  end

  create_table "recipe_ingredients", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "ingredient_id", null: false
    t.text "preparation"
    t.text "qualifier"
    t.decimal "quantity"
    t.string "raw_text", null: false
    t.uuid "recipe_id", null: false
    t.string "unit"
    t.datetime "updated_at", null: false
    t.index ["ingredient_id", "recipe_id"], name: "index_recipe_ingredients_on_ingredient_and_recipe"
    t.index ["ingredient_id"], name: "index_recipe_ingredients_on_ingredient_id"
    t.index ["recipe_id", "ingredient_id"], name: "index_recipe_ingredients_on_recipe_and_ingredient", unique: true
    t.index ["recipe_id"], name: "index_recipe_ingredients_on_recipe_id"
  end

  create_table "recipes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "author_id"
    t.uuid "canonical_ingredient_ids", default: [], null: false, array: true
    t.uuid "category_id"
    t.integer "cook_time_minutes"
    t.datetime "created_at", null: false
    t.string "cuisine"
    t.string "image_url"
    t.integer "prep_time_minutes"
    t.float "ratings"
    t.integer "required_ingredient_count", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_recipes_on_author_id"
    t.index ["canonical_ingredient_ids"], name: "index_recipes_on_canonical_ingredient_ids_gin", using: :gin
    t.index ["category_id"], name: "index_recipes_on_category_id"
    t.index ["title", "author_id"], name: "index_recipes_on_title_and_author_id", unique: true, nulls_not_distinct: true
    t.check_constraint "cardinality(canonical_ingredient_ids) = required_ingredient_count", name: "recipes_canonical_ingredient_ids_count_matches_required"
    t.check_constraint "ratings IS NULL OR ratings >= 0::double precision", name: "ratings_non_negative"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true, where: "(email IS NOT NULL)"
  end

  add_foreign_key "ingredient_parse_errors", "import_runs"
  add_foreign_key "ingredient_parse_errors", "recipes"
  add_foreign_key "pantry_items", "ingredients"
  add_foreign_key "pantry_items", "pantries"
  add_foreign_key "pantry_items", "users"
  add_foreign_key "recipe_ingredients", "ingredients"
  add_foreign_key "recipe_ingredients", "recipes"
  add_foreign_key "recipes", "authors"
  add_foreign_key "recipes", "categories"
end
