# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20110901125026) do

  create_table "assignments", force: :cascade do |t|
    t.integer  "contract_id", limit: 4
    t.string   "name",        limit: 100,   default: "",   null: false
    t.text     "description", limit: 65535
    t.date     "due_date"
    t.boolean  "active",                    default: true, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "creator_id",  limit: 4
    t.integer  "weighting",   limit: 1,     default: 10,   null: false
  end

  add_index "assignments", ["contract_id"], name: "index_assignments_on_contract_id", using: :btree
  add_index "assignments", ["creator_id"], name: "index_assignments_on_creator_id", using: :btree

  create_table "categories", force: :cascade do |t|
    t.string  "name",       limit: 255
    t.integer "sequence",   limit: 4,   default: 0,     null: false
    t.boolean "public",                 default: false
    t.integer "statusable", limit: 1,   default: 0
    t.integer "homeroom",   limit: 1,   default: 0
  end

  add_index "categories", ["public"], name: "index_categories_on_public", using: :btree

  create_table "contract_ealrs", id: false, force: :cascade do |t|
    t.integer "contract_id", limit: 4
    t.integer "ealr_id",     limit: 4
  end

  add_index "contract_ealrs", ["contract_id"], name: "index_contract_ealrs_on_contract_id", using: :btree
  add_index "contract_ealrs", ["ealr_id"], name: "index_contract_ealrs_on_ealr_id", using: :btree

  create_table "contracts", force: :cascade do |t|
    t.string   "name",                    limit: 255,   default: "", null: false
    t.integer  "category_id",             limit: 4,     default: 0,  null: false
    t.text     "learning_objectives",     limit: 65535
    t.text     "competencies",            limit: 65535
    t.text     "evaluation_methods",      limit: 65535
    t.text     "instructional_materials", limit: 65535
    t.integer  "facilitator_id",          limit: 4,     default: 0,  null: false
    t.integer  "creator_id",              limit: 4,     default: 0,  null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "term_id",                 limit: 4,     default: 0,  null: false
    t.string   "location",                limit: 255
    t.text     "timeslots",               limit: 65535
    t.integer  "contract_status",         limit: 4,     default: 0,  null: false
  end

  add_index "contracts", ["category_id"], name: "index_contracts_on_category_id", using: :btree
  add_index "contracts", ["facilitator_id", "category_id", "term_id"], name: "index_contracts_on_fac_cat_term", using: :btree
  add_index "contracts", ["facilitator_id"], name: "index_contracts_on_facilitator_id", using: :btree
  add_index "contracts", ["term_id"], name: "index_contracts_on_term_id", using: :btree

  create_table "credit_assignments", force: :cascade do |t|
    t.integer  "credit_id",                     limit: 4,   default: 0
    t.float    "credit_hours",                  limit: 24,  default: 0.5, null: false
    t.date     "enrollment_finalized_on"
    t.integer  "enrollment_id",                 limit: 4
    t.string   "contract_name",                 limit: 255
    t.string   "contract_facilitator_name",     limit: 255
    t.boolean  "district_finalize_approved"
    t.string   "district_finalize_approved_by", limit: 255
    t.date     "district_finalize_approved_on"
    t.integer  "parent_credit_assignment_id",   limit: 4
    t.integer  "credit_transmittal_batch_id",   limit: 4
    t.integer  "contract_term_id",              limit: 4
    t.integer  "contract_facilitator_id",       limit: 4
    t.date     "district_transmitted_on"
    t.float    "override_hours",                limit: 24
    t.string   "override_by",                   limit: 255
    t.integer  "user_id",                       limit: 4
    t.integer  "contract_id",                   limit: 4
    t.string   "credit_course_name",            limit: 255
    t.string   "credit_course_id",              limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "credit_assignments", ["contract_facilitator_id"], name: "index_credit_assignments_on_contract_facilitator_id", using: :btree
  add_index "credit_assignments", ["contract_id"], name: "index_credit_assignments_on_contract_id", using: :btree
  add_index "credit_assignments", ["contract_term_id"], name: "index_credit_assignments_on_contract_term_id", using: :btree
  add_index "credit_assignments", ["credit_id"], name: "index_credit_assignments_on_credit_id", using: :btree
  add_index "credit_assignments", ["credit_transmittal_batch_id"], name: "index_credit_assignments_on_credit_transmittal_batch_id", using: :btree
  add_index "credit_assignments", ["enrollment_id"], name: "index_credit_assignments_on_enrollment_id", using: :btree
  add_index "credit_assignments", ["parent_credit_assignment_id"], name: "index_credit_assignments_on_parent_credit_assignment_id", using: :btree
  add_index "credit_assignments", ["user_id"], name: "index_credit_assignments_on_user_id", using: :btree

  create_table "credit_transmittal_batches", force: :cascade do |t|
    t.date   "finalized_on"
    t.string "finalized_by",          limit: 255, default: "", null: false
    t.date   "transmitted_on"
    t.string "transmitted_by",        limit: 255
    t.string "transmitted_signature", limit: 255
  end

  create_table "credits", force: :cascade do |t|
    t.string  "course_name",    limit: 255, default: "",  null: false
    t.string  "course_id",      limit: 255, default: "0", null: false
    t.integer "course_type",    limit: 4,   default: 0,   null: false
    t.float   "required_hours", limit: 24,  default: 0.0, null: false
  end

  create_table "ealrs", force: :cascade do |t|
    t.string "category", limit: 255
    t.string "seq",      limit: 255
    t.text   "ealr",     limit: 65535
    t.date   "version"
  end

  create_table "enrollments", force: :cascade do |t|
    t.integer  "contract_id",       limit: 4, default: 0, null: false
    t.integer  "participant_id",    limit: 4, default: 0, null: false
    t.integer  "role",              limit: 4, default: 0, null: false
    t.integer  "enrollment_status", limit: 4, default: 0, null: false
    t.integer  "completion_status", limit: 4, default: 0, null: false
    t.date     "completion_date"
    t.integer  "creator_id",        limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.date     "finalized_on"
  end

  add_index "enrollments", ["contract_id"], name: "index_enrollments_on_contract_id", using: :btree
  add_index "enrollments", ["participant_id"], name: "index_enrollments_on_participant_id", using: :btree
  add_index "enrollments", ["role"], name: "index_enrollments_on_role", using: :btree

  create_table "graduation_plan_mappings", force: :cascade do |t|
    t.integer "graduation_plan_id",             limit: 4,               null: false
    t.integer "credit_assignment_id",           limit: 4
    t.integer "graduation_plan_requirement_id", limit: 4,               null: false
    t.string  "name",                           limit: 255
    t.date    "date_completed"
    t.integer "quantity",                       limit: 4,   default: 0
  end

  add_index "graduation_plan_mappings", ["credit_assignment_id"], name: "index_graduation_plan_mappings_on_credit_assignment_id", using: :btree
  add_index "graduation_plan_mappings", ["graduation_plan_id"], name: "index_graduation_plan_mappings_on_graduation_plan_id", using: :btree
  add_index "graduation_plan_mappings", ["graduation_plan_requirement_id"], name: "index_graduation_plan_mappings_on_graduation_plan_requirement_id", using: :btree

  create_table "graduation_plan_requirements", force: :cascade do |t|
    t.string  "name",             limit: 255,                      null: false
    t.text    "notes",            limit: 65535
    t.integer "position",         limit: 4,     default: 0
    t.integer "parent_id",        limit: 4
    t.string  "requirement_type", limit: 7,     default: "credit", null: false
  end

  add_index "graduation_plan_requirements", ["parent_id"], name: "index_graduation_plan_requirements_on_parent_id", using: :btree
  add_index "graduation_plan_requirements", ["requirement_type"], name: "index_graduation_plan_requirements_on_requirement_type", using: :btree

  create_table "graduation_plans", force: :cascade do |t|
    t.integer "user_id",  limit: 4
    t.string  "class_of", limit: 255
  end

  create_table "learning_plan_goals", force: :cascade do |t|
    t.text    "description", limit: 65535
    t.boolean "required",                  default: false
    t.boolean "active",                    default: true
    t.integer "position",    limit: 4
  end

  create_table "learning_plans", force: :cascade do |t|
    t.integer "user_id",      limit: 4,     default: 0, null: false
    t.integer "year",         limit: 4,     default: 0, null: false
    t.text    "user_goals",   limit: 65535
    t.integer "weekly_hours", limit: 4,     default: 0, null: false
  end

  add_index "learning_plans", ["user_id", "year"], name: "index_learning_plans_on_user_id_and_year", using: :btree

  create_table "learning_plans_to_goals", id: false, force: :cascade do |t|
    t.integer "learning_plan_id",      limit: 4
    t.integer "learning_plan_goal_id", limit: 4
  end

  add_index "learning_plans_to_goals", ["learning_plan_goal_id"], name: "index_lp_to_goals_on_goal_id", using: :btree
  add_index "learning_plans_to_goals", ["learning_plan_id"], name: "index_lp_to_goals_on_lp_id", using: :btree

  create_table "meeting_participants", force: :cascade do |t|
    t.integer "meeting_id",    limit: 4
    t.integer "enrollment_id", limit: 4
    t.integer "participation", limit: 4
    t.string  "contact_type",  limit: 8, default: "class"
  end

  add_index "meeting_participants", ["enrollment_id"], name: "index_meeting_participants_on_enrollment_id", using: :btree
  add_index "meeting_participants", ["meeting_id"], name: "index_meeting_participants_on_meeting_id", using: :btree

  create_table "meetings", force: :cascade do |t|
    t.integer "contract_id",  limit: 4
    t.date    "meeting_date"
    t.string  "title",        limit: 255
  end

  add_index "meetings", ["contract_id"], name: "index_meetings_on_contract_id", using: :btree

  create_table "notes", force: :cascade do |t|
    t.text     "note",         limit: 65535
    t.integer  "creator_id",   limit: 4
    t.datetime "updated_at"
    t.integer  "notable_id",   limit: 4
    t.string   "notable_type", limit: 255
  end

  add_index "notes", ["notable_type", "notable_id"], name: "index_notes_on_notable", using: :btree
  add_index "notes", ["notable_type"], name: "index_notes_on_notable_type", using: :btree

  create_table "sessions", force: :cascade do |t|
    t.string   "session_id", limit: 255
    t.text     "data",       limit: 65535
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], name: "sessions_session_id_index", using: :btree

  create_table "settings", force: :cascade do |t|
    t.string "name",  limit: 255
    t.text   "value", limit: 65535
  end

  add_index "settings", ["name"], name: "index_settings_on_name", using: :btree
  add_index "settings", ["name"], name: "index_settings_on_setting_name", using: :btree

  create_table "statuses", force: :cascade do |t|
    t.date     "month"
    t.integer  "academic_status",        limit: 4,   default: 0,     null: false
    t.integer  "attendance_status",      limit: 4,   default: 0,     null: false
    t.integer  "creator_id",             limit: 4,   default: 0,     null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "statusable_id",          limit: 4
    t.string   "statusable_type",        limit: 255
    t.integer  "fte_hours",              limit: 4,   default: 25
    t.boolean  "met_fte_requirements",               default: true
    t.boolean  "held_periodic_checkins",             default: false
  end

  add_index "statuses", ["statusable_id", "statusable_type", "month"], name: "index_statuses_on_statusable_and_month", unique: true, using: :btree
  add_index "statuses", ["statusable_type", "statusable_id"], name: "index_status_on_statusable", using: :btree

  create_table "terms", force: :cascade do |t|
    t.string  "name",        limit: 255,   default: "",   null: false
    t.integer "school_year", limit: 4
    t.boolean "active",                    default: true, null: false
    t.text    "months",      limit: 65535
    t.date    "credit_date"
  end

  add_index "terms", ["active"], name: "index_terms_on_active", using: :btree

  create_table "turnins", force: :cascade do |t|
    t.integer  "enrollment_id", limit: 4,  default: 0,         null: false
    t.integer  "assignment_id", limit: 4,  default: 0,         null: false
    t.string   "status",        limit: 11, default: "missing", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "turnins", ["assignment_id"], name: "index_turnins_on_assignment_id", using: :btree
  add_index "turnins", ["enrollment_id", "assignment_id"], name: "index_turnins_on_enrollment_id_and_assignment_id", unique: true, using: :btree
  add_index "turnins", ["enrollment_id"], name: "index_turnins_on_enrollment_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string  "login",          limit: 255
    t.integer "login_status",   limit: 4,   default: 0
    t.string  "first_name",     limit: 255
    t.string  "last_name",      limit: 255
    t.string  "nickname",       limit: 255
    t.string  "email",          limit: 255
    t.integer "privilege",      limit: 4,   default: 0, null: false
    t.integer "status",         limit: 4
    t.string  "district_id",    limit: 255
    t.integer "district_grade", limit: 4
    t.string  "password_hash",  limit: 255
    t.string  "password_salt",  limit: 255
    t.integer "coordinator_id", limit: 4
    t.date    "date_active"
    t.date    "date_inactive"
  end

  add_index "users", ["coordinator_id"], name: "index_users_on_coordinator_id", using: :btree
  add_index "users", ["date_active", "date_inactive"], name: "index_users_on_active_dates", using: :btree
  add_index "users", ["date_active"], name: "index_users_on_date_active", using: :btree
  add_index "users", ["date_inactive"], name: "index_users_on_date_inactive", using: :btree
  add_index "users", ["privilege"], name: "index_users_on_privilege", using: :btree
  add_index "users", ["status"], name: "index_users_on_user_status", using: :btree

  add_foreign_key "credit_assignments", "contracts", name: "credit_assignments_ibfk_contract_id", on_delete: :nullify
  add_foreign_key "credit_assignments", "credits", name: "credit_assignments_ibfk_credit_id", on_delete: :nullify
  add_foreign_key "credit_assignments", "enrollments", name: "credit_assignments_ibfk_enrollment_id", on_delete: :cascade
  add_foreign_key "credit_assignments", "users", name: "credit_assignments_ibfk_user_id"
end
