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

ActiveRecord::Schema[8.1].define(version: 2026_05_30_000001) do
  create_table "ballot_options", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "label", null: false
    t.integer "poll_id", null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "votes_count", default: 0, null: false
    t.index ["poll_id"], name: "index_ballot_options_on_poll_id"
  end

  create_table "ballot_polls", force: :cascade do |t|
    t.boolean "ai_generated", default: false, null: false
    t.string "asker"
    t.datetime "created_at", null: false
    t.integer "position", default: 0, null: false
    t.string "question", null: false
    t.integer "room_id", null: false
    t.datetime "updated_at", null: false
    t.index ["room_id"], name: "index_ballot_polls_on_room_id"
  end

  create_table "ballot_questions", force: :cascade do |t|
    t.string "author", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.integer "room_id", null: false
    t.datetime "updated_at", null: false
    t.integer "upvotes_count", default: 0, null: false
    t.index ["room_id", "upvotes_count"], name: "index_ballot_questions_on_room_id_and_upvotes_count"
    t.index ["room_id"], name: "index_ballot_questions_on_room_id"
  end

  create_table "ballot_rooms", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.string "subtitle"
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_ballot_rooms_on_slug", unique: true
  end

  create_table "channels", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.text "topic"
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_channels_on_slug", unique: true
  end

  create_table "columns", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.integer "project_id", null: false
    t.datetime "updated_at", null: false
    t.integer "wip_limit"
    t.index ["project_id", "position"], name: "index_columns_on_project_id_and_position"
    t.index ["project_id"], name: "index_columns_on_project_id"
  end

  create_table "comments", force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.integer "issue_id", null: false
    t.integer "member_id"
    t.datetime "updated_at", null: false
    t.index ["issue_id"], name: "index_comments_on_issue_id"
    t.index ["member_id"], name: "index_comments_on_member_id"
  end

  create_table "grid_rows", force: :cascade do |t|
    t.string "category", default: "—", null: false
    t.datetime "created_at", null: false
    t.string "label", null: false
    t.integer "position", default: 0, null: false
    t.integer "qty", default: 1, null: false
    t.integer "sheet_id", null: false
    t.integer "unit_price", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["sheet_id"], name: "index_grid_rows_on_sheet_id"
  end

  create_table "grid_sheets", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.string "unit", default: "$", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_grid_sheets_on_slug", unique: true
  end

  create_table "issues", force: :cascade do |t|
    t.integer "assignee_id"
    t.integer "column_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "label", default: "feature", null: false
    t.integer "number", null: false
    t.integer "points", default: 0, null: false
    t.integer "position", default: 0, null: false
    t.string "priority", default: "medium", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["assignee_id"], name: "index_issues_on_assignee_id"
    t.index ["column_id", "position"], name: "index_issues_on_column_id_and_position"
    t.index ["column_id"], name: "index_issues_on_column_id"
  end

  create_table "members", force: :cascade do |t|
    t.string "color", default: "indigo", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "role", default: "Engineer", null: false
    t.datetime "updated_at", null: false
  end

  create_table "messages", force: :cascade do |t|
    t.text "body", null: false
    t.integer "channel_id", null: false
    t.datetime "created_at", null: false
    t.integer "member_id"
    t.text "reactions", default: "{}", null: false
    t.datetime "updated_at", null: false
    t.index ["channel_id"], name: "index_messages_on_channel_id"
    t.index ["member_id"], name: "index_messages_on_member_id"
  end

  create_table "projects", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "issues_seq", default: 0, null: false
    t.string "key", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_projects_on_key", unique: true
    t.index ["slug"], name: "index_projects_on_slug", unique: true
  end

  create_table "pulse_incidents", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "service_id"
    t.string "severity", default: "sev3", null: false
    t.datetime "started_at", null: false
    t.string "status", default: "open", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["service_id"], name: "index_pulse_incidents_on_service_id"
  end

  create_table "pulse_services", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.float "error_rate", default: 0.2, null: false
    t.integer "latency_ms", default: 80, null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.text "samples", default: "[]", null: false
    t.string "slug", null: false
    t.string "status", default: "healthy", null: false
    t.integer "throughput", default: 1200, null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_pulse_services_on_slug", unique: true
  end

  create_table "spindle_albums", force: :cascade do |t|
    t.string "artist", null: false
    t.datetime "created_at", null: false
    t.string "hue", default: "#7c3aed", null: false
    t.string "mood"
    t.integer "position", default: 0, null: false
    t.string "slug", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_spindle_albums_on_slug", unique: true
  end

  create_table "spindle_tracks", force: :cascade do |t|
    t.integer "album_id", null: false
    t.integer "bpm", default: 84, null: false
    t.datetime "created_at", null: false
    t.string "duration_label", default: "3:00", null: false
    t.integer "position", default: 0, null: false
    t.string "roots", null: false
    t.string "texture", default: "keys", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["album_id"], name: "index_spindle_tracks_on_album_id"
  end

  add_foreign_key "ballot_options", "ballot_polls", column: "poll_id"
  add_foreign_key "ballot_polls", "ballot_rooms", column: "room_id"
  add_foreign_key "ballot_questions", "ballot_rooms", column: "room_id"
  add_foreign_key "columns", "projects"
  add_foreign_key "comments", "issues"
  add_foreign_key "comments", "members"
  add_foreign_key "grid_rows", "grid_sheets", column: "sheet_id"
  add_foreign_key "issues", "columns"
  add_foreign_key "issues", "members", column: "assignee_id"
  add_foreign_key "messages", "channels"
  add_foreign_key "messages", "members"
  add_foreign_key "pulse_incidents", "pulse_services", column: "service_id"
  add_foreign_key "spindle_tracks", "spindle_albums", column: "album_id"
end
