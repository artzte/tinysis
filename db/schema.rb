# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20110226043501) do

  create_table "assignments", :force => true do |t|
    t.integer  "contract_id"
    t.string   "name",        :limit => 100, :default => "",   :null => false
    t.text     "description"
    t.date     "due_date"
    t.boolean  "active",                     :default => true, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "creator_id"
    t.integer  "weighting",   :limit => 1,   :default => 10,   :null => false
  end

  add_index "assignments", ["contract_id"], :name => "index_assignments_on_contract_id"
  add_index "assignments", ["creator_id"], :name => "index_assignments_on_creator_id"

  create_table "categories", :force => true do |t|
    t.string  "name"
    t.integer "sequence",                :default => 0,     :null => false
    t.boolean "public",                  :default => false
    t.integer "statusable", :limit => 1, :default => 0
  end

  add_index "categories", ["public"], :name => "index_categories_on_public"

  create_table "contract_ealrs", :id => false, :force => true do |t|
    t.integer "contract_id"
    t.integer "ealr_id"
  end

  add_index "contract_ealrs", ["contract_id"], :name => "index_contract_ealrs_on_contract_id"
  add_index "contract_ealrs", ["ealr_id"], :name => "index_contract_ealrs_on_ealr_id"

  create_table "contracts", :force => true do |t|
    t.string   "name",                    :default => "", :null => false
    t.integer  "category_id",             :default => 0,  :null => false
    t.text     "learning_objectives"
    t.text     "competencies"
    t.text     "evaluation_methods"
    t.text     "instructional_materials"
    t.integer  "facilitator_id",          :default => 0,  :null => false
    t.integer  "creator_id",              :default => 0,  :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "term_id",                 :default => 0,  :null => false
    t.string   "location"
    t.text     "timeslots"
    t.integer  "contract_status",         :default => 0,  :null => false
  end

  add_index "contracts", ["category_id"], :name => "index_contracts_on_category_id"
  add_index "contracts", ["facilitator_id", "category_id", "term_id"], :name => "index_contracts_on_fac_cat_term"
  add_index "contracts", ["facilitator_id"], :name => "index_contracts_on_facilitator_id"
  add_index "contracts", ["term_id"], :name => "index_contracts_on_term_id"

  create_table "credit_assignments", :force => true do |t|
    t.integer  "credit_id",                     :default => 0
    t.float    "credit_hours",                  :default => 0.5, :null => false
    t.date     "enrollment_finalized_on"
    t.integer  "enrollment_id"
    t.string   "contract_name"
    t.string   "contract_facilitator_name"
    t.boolean  "district_finalize_approved"
    t.string   "district_finalize_approved_by"
    t.date     "district_finalize_approved_on"
    t.integer  "parent_credit_assignment_id"
    t.integer  "credit_transmittal_batch_id"
    t.integer  "contract_term_id"
    t.integer  "contract_facilitator_id"
    t.date     "district_transmitted_on"
    t.float    "override_hours"
    t.string   "override_by"
    t.integer  "user_id"
    t.integer  "contract_id"
    t.string   "credit_course_name"
    t.string   "credit_course_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "credit_assignments", ["contract_facilitator_id"], :name => "index_credit_assignments_on_contract_facilitator_id"
  add_index "credit_assignments", ["contract_id"], :name => "index_credit_assignments_on_contract_id"
  add_index "credit_assignments", ["contract_term_id"], :name => "index_credit_assignments_on_contract_term_id"
  add_index "credit_assignments", ["credit_id"], :name => "index_credit_assignments_on_credit_id"
  add_index "credit_assignments", ["credit_transmittal_batch_id"], :name => "index_credit_assignments_on_credit_transmittal_batch_id"
  add_index "credit_assignments", ["enrollment_finalized_on"], :name => "index_credit_assignments_on_enrollment_finalized_on"
  add_index "credit_assignments", ["enrollment_id"], :name => "index_credit_assignments_on_enrollment_id"
  add_index "credit_assignments", ["parent_credit_assignment_id"], :name => "index_credit_assignments_on_parent_credit_assignment_id"
  add_index "credit_assignments", ["user_id"], :name => "index_credit_assignments_on_user_id"

  create_table "credit_transmittal_batches", :force => true do |t|
    t.date   "finalized_on"
    t.string "finalized_by",          :default => "", :null => false
    t.date   "transmitted_on"
    t.string "transmitted_by"
    t.string "transmitted_signature"
  end

  create_table "credits", :force => true do |t|
    t.string  "course_name",    :default => "",  :null => false
    t.string  "course_id",      :default => "0", :null => false
    t.integer "course_type",    :default => 0,   :null => false
    t.float   "required_hours", :default => 0.0, :null => false
  end

  create_table "ealrs", :force => true do |t|
    t.string "category"
    t.string "seq"
    t.text   "ealr"
    t.date   "version"
  end

  create_table "enrollments", :force => true do |t|
    t.integer  "contract_id",       :default => 0, :null => false
    t.integer  "participant_id",    :default => 0, :null => false
    t.integer  "role",              :default => 0, :null => false
    t.integer  "enrollment_status", :default => 0, :null => false
    t.integer  "completion_status", :default => 0, :null => false
    t.date     "completion_date"
    t.integer  "creator_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.date     "finalized_on"
  end

  add_index "enrollments", ["contract_id"], :name => "index_enrollments_on_contract_id"
  add_index "enrollments", ["participant_id"], :name => "index_enrollments_on_participant_id"
  add_index "enrollments", ["role"], :name => "index_enrollments_on_role"

  create_table "graduation_plan_mappings", :force => true do |t|
    t.integer "graduation_plan_id",                            :null => false
    t.integer "credit_assignment_id"
    t.integer "graduation_plan_requirement_id",                :null => false
    t.string  "name"
    t.date    "date_completed"
    t.integer "quantity",                       :default => 0
  end

  add_index "graduation_plan_mappings", ["credit_assignment_id"], :name => "index_graduation_plan_mappings_on_credit_assignment_id"
  add_index "graduation_plan_mappings", ["graduation_plan_id"], :name => "index_graduation_plan_mappings_on_graduation_plan_id"
  add_index "graduation_plan_mappings", ["graduation_plan_requirement_id"], :name => "index_graduation_plan_mappings_on_graduation_plan_requirement_id"

  create_table "graduation_plan_requirements", :force => true do |t|
    t.string  "name",                                                                           :null => false
    t.text    "notes"
    t.integer "position",                                                  :default => 0
    t.integer "parent_id"
    t.enum    "requirement_type", :limit => [:credit, :general, :service], :default => :credit, :null => false
  end

  add_index "graduation_plan_requirements", ["parent_id"], :name => "index_graduation_plan_requirements_on_parent_id"
  add_index "graduation_plan_requirements", ["requirement_type"], :name => "index_graduation_plan_requirements_on_requirement_type"

  create_table "graduation_plans", :force => true do |t|
    t.integer "user_id"
    t.string  "class_of"
  end

  create_table "learning_plan_goals", :force => true do |t|
    t.text    "description"
    t.boolean "required",    :default => false
    t.boolean "active",      :default => true
    t.integer "position"
  end

  create_table "learning_plans", :force => true do |t|
    t.integer "user_id",      :default => 0, :null => false
    t.integer "year",         :default => 0, :null => false
    t.text    "user_goals"
    t.integer "weekly_hours", :default => 0, :null => false
  end

  add_index "learning_plans", ["user_id", "year"], :name => "index_learning_plans_on_user_id_and_year"

  create_table "learning_plans_to_goals", :id => false, :force => true do |t|
    t.integer "learning_plan_id"
    t.integer "learning_plan_goal_id"
  end

  add_index "learning_plans_to_goals", ["learning_plan_goal_id"], :name => "index_lp_to_goals_on_goal_id"
  add_index "learning_plans_to_goals", ["learning_plan_id"], :name => "index_lp_to_goals_on_lp_id"

  create_table "meeting_participants", :force => true do |t|
    t.integer "meeting_id"
    t.integer "enrollment_id"
    t.integer "participation"
  end

  add_index "meeting_participants", ["enrollment_id"], :name => "index_meeting_participants_on_enrollment_id"
  add_index "meeting_participants", ["meeting_id"], :name => "index_meeting_participants_on_meeting_id"

  create_table "meetings", :force => true do |t|
    t.integer "contract_id"
    t.date    "meeting_date"
  end

  add_index "meetings", ["contract_id"], :name => "index_meetings_on_contract_id"

  create_table "notes", :force => true do |t|
    t.text     "note"
    t.integer  "creator_id"
    t.datetime "updated_at"
    t.integer  "notable_id"
    t.string   "notable_type"
  end

  add_index "notes", ["notable_type", "notable_id"], :name => "index_notes_on_notable"
  add_index "notes", ["notable_type"], :name => "index_notes_on_notable_type"

  create_table "sessions", :force => true do |t|
    t.string   "session_id"
    t.text     "data"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "sessions_session_id_index"

  create_table "settings", :force => true do |t|
    t.string "name"
    t.text   "value"
  end

  add_index "settings", ["name"], :name => "index_settings_on_name"
  add_index "settings", ["name"], :name => "index_settings_on_setting_name"

  create_table "statuses", :force => true do |t|
    t.date     "month"
    t.integer  "academic_status",        :default => 0,     :null => false
    t.integer  "attendance_status",      :default => 0,     :null => false
    t.integer  "creator_id",             :default => 0,     :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "statusable_id"
    t.string   "statusable_type"
    t.integer  "fte_hours",              :default => 25
    t.boolean  "met_fte_requirements",   :default => true
    t.boolean  "held_periodic_checkins", :default => false
  end

  add_index "statuses", ["statusable_id", "statusable_type", "month"], :name => "index_statuses_on_statusable_and_month", :unique => true
  add_index "statuses", ["statusable_type", "statusable_id"], :name => "index_status_on_statusable"

  create_table "terms", :force => true do |t|
    t.string  "name",        :default => "",   :null => false
    t.integer "school_year"
    t.boolean "active",      :default => true, :null => false
    t.text    "months"
    t.date    "credit_date"
  end

  add_index "terms", ["active"], :name => "index_terms_on_active"

  create_table "turnins", :force => true do |t|
    t.integer  "enrollment_id",                                                                    :default => 0,        :null => false
    t.integer  "assignment_id",                                                                    :default => 0,        :null => false
    t.enum     "status",        :limit => [:missing, :incomplete, :complete, :late, :exceptional], :default => :missing, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "turnins", ["assignment_id"], :name => "index_turnins_on_assignment_id"
  add_index "turnins", ["enrollment_id", "assignment_id"], :name => "index_turnins_on_enrollment_id_and_assignment_id", :unique => true
  add_index "turnins", ["enrollment_id"], :name => "index_turnins_on_enrollment_id"

  create_table "users", :force => true do |t|
    t.string  "login"
    t.integer "login_status",    :default => 0
    t.string  "first_name"
    t.string  "last_name"
    t.string  "nickname"
    t.string  "email"
    t.integer "privilege",       :default => 0, :null => false
    t.integer "status"
    t.string  "district_id"
    t.integer "district_grade"
    t.integer "community_grade"
    t.string  "password_hash"
    t.string  "password_salt"
    t.integer "coordinator_id"
    t.date    "date_active"
    t.date    "date_inactive"
  end

  add_index "users", ["coordinator_id"], :name => "index_users_on_coordinator_id"
  add_index "users", ["date_active", "date_inactive"], :name => "index_users_on_active_dates"
  add_index "users", ["date_active"], :name => "index_users_on_date_active"
  add_index "users", ["date_inactive"], :name => "index_users_on_date_inactive"
  add_index "users", ["privilege"], :name => "index_users_on_privilege"
  add_index "users", ["status"], :name => "index_users_on_user_status"

  add_foreign_key "credit_assignments", "contracts", :name => "credit_assignments_ibfk_contract_id", :dependent => :nullify
  add_foreign_key "credit_assignments", "credits", :name => "credit_assignments_ibfk_credit_id", :dependent => :nullify
  add_foreign_key "credit_assignments", "enrollments", :name => "credit_assignments_ibfk_enrollment_id", :dependent => :delete
  add_foreign_key "credit_assignments", "users", :name => "credit_assignments_ibfk_user_id"

end
