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

ActiveRecord::Schema[8.1].define(version: 2026_05_28_195443) do
  create_table "boards", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_boards_on_slug", unique: true
  end

  create_table "cards", force: :cascade do |t|
    t.string "assignee"
    t.text "body"
    t.integer "column_id", null: false
    t.datetime "created_at", null: false
    t.integer "position", default: 0, null: false
    t.string "tag"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["column_id", "position"], name: "index_cards_on_column_id_and_position"
    t.index ["column_id"], name: "index_cards_on_column_id"
  end

  create_table "choices", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "label", null: false
    t.integer "picks_count", default: 0, null: false
    t.integer "position", default: 0, null: false
    t.integer "scene_id", null: false
    t.string "target_key", null: false
    t.datetime "updated_at", null: false
    t.index ["scene_id", "position"], name: "index_choices_on_scene_id_and_position"
    t.index ["scene_id"], name: "index_choices_on_scene_id"
  end

  create_table "columns", force: :cascade do |t|
    t.string "accent", default: "slate", null: false
    t.integer "board_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["board_id", "position"], name: "index_columns_on_board_id_and_position"
    t.index ["board_id"], name: "index_columns_on_board_id"
  end

  create_table "scenes", force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.boolean "ending", default: false, null: false
    t.string "ending_kind"
    t.string "heading", null: false
    t.string "key", null: false
    t.string "mood", default: "calm", null: false
    t.integer "story_id", null: false
    t.datetime "updated_at", null: false
    t.index ["story_id", "key"], name: "index_scenes_on_story_id_and_key", unique: true
    t.index ["story_id"], name: "index_scenes_on_story_id"
  end

  create_table "stories", force: :cascade do |t|
    t.text "blurb"
    t.datetime "created_at", null: false
    t.string "slug", null: false
    t.string "tagline"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_stories_on_slug", unique: true
  end

  add_foreign_key "cards", "columns"
  add_foreign_key "choices", "scenes"
  add_foreign_key "columns", "boards"
  add_foreign_key "scenes", "stories"
end
