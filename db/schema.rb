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

ActiveRecord::Schema.define(version: 2018_07_16_143624) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "additional_contacts", force: :cascade do |t|
    t.string "email", null: false
    t.integer "site_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["site_id"], name: "index_additional_contacts_on_site_id"
  end

  create_table "articles", force: :cascade do |t|
    t.string "title", limit: 255, null: false
    t.string "url", limit: 512, null: false
    t.json "meta", default: "{}", null: false
    t.bigint "topic_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["topic_id"], name: "index_articles_on_topic_id"
  end

  create_table "asset_record_field_definitions", force: :cascade do |t|
    t.string "field_name", null: false
    t.string "level", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "data_type"
  end

  create_table "asset_record_field_definitions_component_types", id: false, force: :cascade do |t|
    t.integer "asset_record_field_definition_id", null: false
    t.integer "component_type_id", null: false
    t.index ["asset_record_field_definition_id"], name: "index_arfd_ct_on_asset_record_field_definition_id"
    t.index ["component_type_id"], name: "index_arfd_ct_on_component_type_id"
  end

  create_table "asset_record_fields", force: :cascade do |t|
    t.string "value", null: false
    t.integer "component_id"
    t.integer "component_group_id"
    t.integer "asset_record_field_definition_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["asset_record_field_definition_id"], name: "index_asset_record_fields_on_asset_record_field_definition_id"
    t.index ["component_group_id"], name: "index_asset_record_fields_on_component_group_id"
    t.index ["component_id"], name: "index_asset_record_fields_on_component_id"
  end

  create_table "audits", force: :cascade do |t|
    t.integer "auditable_id"
    t.string "auditable_type"
    t.integer "associated_id"
    t.string "associated_type"
    t.integer "user_id"
    t.string "user_type"
    t.string "username"
    t.string "action"
    t.jsonb "audited_changes"
    t.integer "version", default: 0
    t.string "comment"
    t.string "remote_address"
    t.string "request_uuid"
    t.datetime "created_at"
    t.index ["associated_type", "associated_id"], name: "associated_index"
    t.index ["auditable_type", "auditable_id"], name: "auditable_index"
    t.index ["created_at"], name: "index_audits_on_created_at"
    t.index ["request_uuid"], name: "index_audits_on_request_uuid"
    t.index ["user_id", "user_type"], name: "user_index"
  end

  create_table "case_associations", force: :cascade do |t|
    t.bigint "case_id", null: false
    t.string "associated_element_type", null: false
    t.bigint "associated_element_id", null: false
    t.index ["associated_element_type", "associated_element_id"], name: "index_case_associations_by_assoc_element"
    t.index ["case_id", "associated_element_id", "associated_element_type"], name: "index_case_associations_uniqueness", unique: true
    t.index ["case_id"], name: "index_case_associations_on_case_id"
  end

  create_table "case_comments", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "case_id", null: false
    t.string "text", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["case_id"], name: "index_case_comments_on_case_id"
    t.index ["user_id"], name: "index_case_comments_on_user_id"
  end

  create_table "case_state_transitions", force: :cascade do |t|
    t.bigint "case_id", null: false
    t.string "namespace"
    t.string "event"
    t.string "from"
    t.string "to", null: false
    t.datetime "created_at", null: false
    t.bigint "user_id", null: false
    t.index ["case_id"], name: "index_case_state_transitions_on_case_id"
    t.index ["user_id"], name: "index_case_state_transitions_on_user_id"
  end

  create_table "cases", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "cluster_id", null: false
    t.integer "user_id", null: false
    t.bigint "rt_ticket_id"
    t.integer "issue_id", null: false
    t.text "token", null: false
    t.text "subject", null: false
    t.datetime "completed_at"
    t.integer "tier_level", null: false
    t.json "fields"
    t.text "state", default: "open", null: false
    t.bigint "assignee_id"
    t.string "display_id", null: false
    t.integer "time_worked", default: 0, null: false
    t.boolean "comments_enabled", default: false
    t.index ["assignee_id"], name: "index_cases_on_assignee_id"
    t.index ["cluster_id"], name: "index_cases_on_cluster_id"
    t.index ["display_id"], name: "index_cases_on_display_id", unique: true
    t.index ["issue_id"], name: "index_cases_on_issue_id"
    t.index ["rt_ticket_id"], name: "index_cases_on_rt_ticket_id", unique: true
    t.index ["user_id"], name: "index_cases_on_user_id"
  end

  create_table "cases_logs", id: false, force: :cascade do |t|
    t.bigint "case_id", null: false
    t.bigint "log_id", null: false
  end

  create_table "categories", force: :cascade do |t|
    t.string "name", null: false
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "change_motd_request_state_transitions", force: :cascade do |t|
    t.bigint "change_motd_request_id", null: false
    t.string "namespace"
    t.string "event"
    t.string "from"
    t.string "to", null: false
    t.datetime "created_at", null: false
    t.bigint "user_id", null: false
    t.index ["change_motd_request_id"], name: "index_cmrst_on_cmr_id"
    t.index ["user_id"], name: "index_change_motd_request_state_transitions_on_user_id"
  end

  create_table "change_motd_requests", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "motd", null: false
    t.bigint "case_id", null: false
    t.text "state", null: false
    t.index ["case_id"], name: "index_change_motd_requests_on_case_id"
  end

  create_table "change_request_state_transitions", force: :cascade do |t|
    t.bigint "change_request_id"
    t.string "namespace"
    t.string "event"
    t.string "from"
    t.string "to"
    t.datetime "created_at"
    t.bigint "user_id", null: false
    t.index ["change_request_id"], name: "index_change_request_state_transitions_on_change_request_id"
    t.index ["user_id"], name: "index_change_request_state_transitions_on_user_id"
  end

  create_table "change_requests", force: :cascade do |t|
    t.bigint "case_id"
    t.string "state", default: "draft", null: false
    t.string "description", null: false
    t.integer "credit_charge", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["case_id"], name: "index_change_requests_on_case_id"
  end

  create_table "clusters", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "support_type", null: false
    t.integer "site_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "canonical_name", null: false
    t.string "charging_info"
    t.string "shortcode", null: false
    t.integer "case_index", default: 0, null: false
    t.text "motd"
    t.index ["shortcode"], name: "index_clusters_on_shortcode", unique: true
    t.index ["site_id"], name: "index_clusters_on_site_id"
  end

  create_table "component_groups", force: :cascade do |t|
    t.string "name", null: false
    t.integer "cluster_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "component_make_id", null: false
    t.index ["cluster_id"], name: "index_component_groups_on_cluster_id"
    t.index ["component_make_id"], name: "index_component_groups_on_component_make_id"
  end

  create_table "component_makes", force: :cascade do |t|
    t.string "manufacturer", null: false
    t.string "model", null: false
    t.string "knowledgebase_url", null: false
    t.bigint "component_type_id", null: false
    t.index ["component_type_id"], name: "index_component_makes_on_component_type_id"
  end

  create_table "component_types", force: :cascade do |t|
    t.string "name", null: false
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "ordering", null: false
  end

  create_table "components", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "component_group_id", null: false
    t.string "support_type", default: "inherit", null: false
    t.boolean "internal", default: false
    t.index ["component_group_id"], name: "index_components_on_component_group_id"
  end

  create_table "credit_charges", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "case_id", null: false
    t.bigint "user_id", null: false
    t.integer "amount", null: false
    t.index ["case_id"], name: "index_credit_charges_on_case_id"
    t.index ["user_id"], name: "index_credit_charges_on_user_id"
  end

  create_table "credit_deposits", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "cluster_id", null: false
    t.bigint "user_id", null: false
    t.integer "amount", null: false
    t.index ["cluster_id"], name: "index_credit_deposits_on_cluster_id"
    t.index ["user_id"], name: "index_credit_deposits_on_user_id"
  end

  create_table "data_migrations", primary_key: "version", id: :string, force: :cascade do |t|
  end

  create_table "encryption_keys", force: :cascade do |t|
    t.text "public_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "expansion_types", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "expansions", force: :cascade do |t|
    t.string "slot", null: false
    t.integer "ports", null: false
    t.bigint "expansion_type_id", null: false
    t.string "type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "component_make_id"
    t.bigint "component_id"
    t.index ["component_id"], name: "index_expansions_on_component_id"
    t.index ["component_make_id"], name: "index_expansions_on_component_make_id"
    t.index ["expansion_type_id"], name: "index_expansions_on_expansion_type_id"
  end

  create_table "flight_directory_configs", force: :cascade do |t|
    t.string "hostname", limit: 255, null: false
    t.string "username", limit: 255, null: false
    t.bigint "site_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "encrypted_ssh_key", limit: 4096, null: false
    t.index ["site_id"], name: "index_flight_directory_configs_on_site_id"
  end

  create_table "issues", force: :cascade do |t|
    t.string "name", null: false
    t.boolean "requires_component", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "identifier"
    t.boolean "requires_service", default: false, null: false
    t.bigint "service_type_id"
    t.bigint "category_id"
    t.index ["category_id"], name: "index_issues_on_category_id"
    t.index ["service_type_id"], name: "index_issues_on_service_type_id"
  end

  create_table "logs", force: :cascade do |t|
    t.text "details", null: false
    t.bigint "cluster_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "component_id"
    t.index ["cluster_id"], name: "index_logs_on_cluster_id"
    t.index ["component_id"], name: "index_logs_on_component_id"
    t.index ["user_id"], name: "index_logs_on_user_id"
  end

  create_table "maintenance_window_associations", force: :cascade do |t|
    t.bigint "maintenance_window_id", null: false
    t.string "associated_element_type", null: false
    t.bigint "associated_element_id", null: false
    t.index ["associated_element_type", "associated_element_id"], name: "index_mw_associations_by_assoc_element"
    t.index ["maintenance_window_id", "associated_element_id", "associated_element_type"], name: "index_mw_associations_uniqueness", unique: true
    t.index ["maintenance_window_id"], name: "index_maintenance_window_associations_on_maintenance_window_id"
  end

  create_table "maintenance_window_state_transitions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "maintenance_window_id", null: false
    t.string "namespace"
    t.string "event"
    t.string "from"
    t.string "to", null: false
    t.bigint "user_id"
    t.datetime "requested_start"
    t.integer "duration"
    t.index ["maintenance_window_id"], name: "index_mwst_on_mw_id"
    t.index ["user_id"], name: "index_maintenance_window_state_transitions_on_user_id"
  end

  create_table "maintenance_windows", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "case_id", null: false
    t.text "state", default: "new", null: false
    t.datetime "requested_start", null: false
    t.integer "duration", null: false
    t.boolean "maintenance_ending_soon_email_sent", default: false
    t.index ["case_id"], name: "index_maintenance_windows_on_case_id"
  end

  create_table "notes", force: :cascade do |t|
    t.text "description", null: false
    t.string "flavour", limit: 64, null: false
    t.bigint "cluster_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cluster_id"], name: "index_notes_on_cluster_id"
    t.index ["flavour", "cluster_id"], name: "index_notes_on_flavour_and_cluster_id", unique: true
  end

  create_table "service_types", force: :cascade do |t|
    t.string "name", null: false
    t.string "description"
    t.boolean "automatic", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "services", force: :cascade do |t|
    t.string "name", null: false
    t.string "support_type", default: "inherit", null: false
    t.bigint "service_type_id", null: false
    t.bigint "cluster_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "internal", default: false
    t.index ["cluster_id"], name: "index_services_on_cluster_id"
    t.index ["service_type_id"], name: "index_services_on_service_type_id"
  end

  create_table "sites", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "canonical_name", null: false
  end

  create_table "tiers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "level", null: false
    t.json "fields"
    t.bigint "issue_id", null: false
    t.text "tool"
    t.index ["issue_id"], name: "index_tiers_on_issue_id"
  end

  create_table "topics", force: :cascade do |t|
    t.string "title", limit: 255, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name", null: false
    t.string "email", null: false
    t.string "encrypted_password", limit: 128, null: false
    t.string "remember_token", limit: 128, null: false
    t.integer "site_id"
    t.string "confirmation_token", limit: 128
    t.text "role", null: false
    t.index ["email"], name: "index_users_on_email"
    t.index ["remember_token"], name: "index_users_on_remember_token"
    t.index ["site_id"], name: "index_users_on_site_id"
  end

  add_foreign_key "additional_contacts", "sites"
  add_foreign_key "articles", "topics"
  add_foreign_key "asset_record_field_definitions_component_types", "asset_record_field_definitions"
  add_foreign_key "asset_record_field_definitions_component_types", "component_types"
  add_foreign_key "asset_record_fields", "asset_record_field_definitions"
  add_foreign_key "asset_record_fields", "component_groups"
  add_foreign_key "asset_record_fields", "components"
  add_foreign_key "case_associations", "cases"
  add_foreign_key "case_comments", "cases"
  add_foreign_key "case_comments", "users"
  add_foreign_key "case_state_transitions", "cases"
  add_foreign_key "case_state_transitions", "users"
  add_foreign_key "cases", "clusters"
  add_foreign_key "cases", "issues"
  add_foreign_key "cases", "users"
  add_foreign_key "cases", "users", column: "assignee_id"
  add_foreign_key "change_motd_request_state_transitions", "change_motd_requests"
  add_foreign_key "change_motd_request_state_transitions", "users"
  add_foreign_key "change_request_state_transitions", "change_requests"
  add_foreign_key "change_request_state_transitions", "users"
  add_foreign_key "change_requests", "cases"
  add_foreign_key "clusters", "sites"
  add_foreign_key "component_groups", "clusters"
  add_foreign_key "component_groups", "component_makes"
  add_foreign_key "component_makes", "component_types"
  add_foreign_key "components", "component_groups"
  add_foreign_key "credit_charges", "cases"
  add_foreign_key "credit_charges", "users"
  add_foreign_key "credit_deposits", "clusters"
  add_foreign_key "credit_deposits", "users"
  add_foreign_key "expansions", "component_makes"
  add_foreign_key "expansions", "components"
  add_foreign_key "expansions", "expansion_types"
  add_foreign_key "flight_directory_configs", "sites"
  add_foreign_key "issues", "categories"
  add_foreign_key "issues", "service_types"
  add_foreign_key "logs", "components"
  add_foreign_key "maintenance_window_associations", "maintenance_windows"
  add_foreign_key "maintenance_window_state_transitions", "maintenance_windows"
  add_foreign_key "maintenance_window_state_transitions", "users"
  add_foreign_key "maintenance_windows", "cases"
  add_foreign_key "notes", "clusters"
  add_foreign_key "services", "clusters"
  add_foreign_key "services", "service_types"
  add_foreign_key "users", "sites"
end
