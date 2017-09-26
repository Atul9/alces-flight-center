# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170926110331) do

  create_table "case_categories", force: :cascade do |t|
    t.string "name", null: false
    t.string "description"
    t.boolean "requires_component", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "component_type_id"
    t.index ["component_type_id"], name: "index_case_categories_on_component_type_id"
  end

  create_table "clusters", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.string "support_type"
    t.integer "site_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["site_id"], name: "index_clusters_on_site_id"
  end

  create_table "component_types", force: :cascade do |t|
    t.string "name", null: false
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "components", force: :cascade do |t|
    t.string "name"
    t.integer "cluster_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "component_type_id"
    t.index ["cluster_id"], name: "index_components_on_cluster_id"
    t.index ["component_type_id"], name: "index_components_on_component_type_id"
  end

  create_table "contacts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name", null: false
    t.string "email", null: false
    t.string "encrypted_password", limit: 128, null: false
    t.string "remember_token", limit: 128, null: false
    t.integer "site_id"
    t.index ["email"], name: "index_contacts_on_email"
    t.index ["remember_token"], name: "index_contacts_on_remember_token"
    t.index ["site_id"], name: "index_contacts_on_site_id"
  end

  create_table "sites", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
