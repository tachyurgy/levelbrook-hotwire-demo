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

ActiveRecord::Schema[8.1].define(version: 2026_05_28_200001) do
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

  add_foreign_key "columns", "projects"
  add_foreign_key "comments", "issues"
  add_foreign_key "comments", "members"
  add_foreign_key "issues", "columns"
  add_foreign_key "issues", "members", column: "assignee_id"
  add_foreign_key "messages", "channels"
  add_foreign_key "messages", "members"
end
