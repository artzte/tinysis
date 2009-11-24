class Big2008Cleanup < ActiveRecord::Migration

  def self.up

    # assignments
    remove_column :assignments, :importance
    remove_column :assignments, :updator_id

    add_column :assignments, :weighting, 'tinyint unsigned', :default => 10, :null => false

    add_index :assignments, :contract_id
    add_index :assignments, :creator_id

    # categories
    remove_column :categories, :publicly_enrollable
    rename_column :categories, :category_name, :name
    add_index :categories, :public
    change_column :categories, :statusable, 'tinyint unsigned'
    
    # contract_ealrs
    add_index :contract_ealrs, :contract_id
    add_index :contract_ealrs, :ealr_id
    
    # contracts
    remove_column :contracts, :contract_type
    remove_column :contracts, :updator_id
    remove_column :contracts, :credits
    add_index :contracts, [:facilitator_id, :category_id, :term_id], :name => 'index_contracts_on_fac_cat_term'
    add_index :contracts, :term_id
    add_index :contracts, :category_id
    add_index :contracts, :facilitator_id
    
    Contract.find(:all).each do |c|
      c.timeslots = c.timeslots.reject{|t| t.empty?}
      c.save!
    end
    
    # credit_assignments
    remove_index :credit_assignments, :name => 'index_credit_assignments_on_creditable_id'
    remove_index :credit_assignments, :name => 'index_credit_assignments_on_creditable_type'
    add_index :credit_assignments, [:creditable_type, :creditable_id], :name => 'index_credit_assignments_on_creditable'
    add_index :credit_assignments, :credit_id
    add_index :credit_assignments, :enrollment_id
    add_index :credit_assignments, :parent_credit_assignment_id
    add_index :credit_assignments, :credit_transmittal_batch_id
    add_index :credit_assignments, :contract_term_id
    add_index :credit_assignments, :contract_facilitator_id
    
    # enrollments
    add_index :enrollments, :contract_id
    add_index :enrollments, :participant_id
    remove_column :enrollments, :updator_id
    
    #learning_plan
    rename_table :learningplans, :learning_plans
    add_index :learning_plans, [:user_id,:year]
    
    #learning_plan_goals
    rename_table :learningplan_goals, :learning_plan_goals
    
    #learning_plan_plan_goals
    rename_table :learningplan_plan_goals, :learning_plans_to_goals
    rename_column :learning_plans_to_goals, :learningplan_id, :learning_plan_id
    rename_column :learning_plans_to_goals, :learningplan_goal_id, :learning_plan_goal_id
    add_index :learning_plans_to_goals, :learning_plan_id, :name => 'index_lp_to_goals_on_lp_id'
    add_index :learning_plans_to_goals, :learning_plan_goal_id, :name => 'index_lp_to_goals_on_goal_id'
    
    # meeting_participants
    add_index :meeting_participants, :meeting_id
    add_index :meeting_participants, :enrollment_id
    
    # meetings
    add_index :meetings, :contract_id
    
    # notes
    remove_column :notes, :created_at
    add_index :notes, [:notable_type, :notable_id], :name => 'index_notes_on_notable'
    
    # settings
    rename_column :settings, :setting_name, :name
    rename_column :settings, :setting_value, :value
    add_index :settings, :name
    
    # Add a period "name" to the period serialized array
    periods = Setting.periods
    periods.each_with_index do |period,i|
      period.period = i+1
    end
    Setting.periods=periods
    
    # statuses
    remove_index :statuses, :name => 'index_statuses_on_statusable_type'
    remove_index :statuses, :name => 'index_statuses_on_statusable_id'
    add_index :statuses, [:statusable_type, :statusable_id], :name => 'index_status_on_statusable'
    
    #terms
    rename_column :terms, :schoolyear, :school_year
    remove_column :terms, :term
    add_index :terms, :active
    
    #turnins
    add_column :turnins, :status, :enum, :limit => Turnin::STATUS_TYPES, :default => Turnin::STATUS_TYPES.first, :null => false
    Turnin.update_all("status='complete'","complete=1")
    remove_column :turnins, :complete

    add_index :turnins, [:enrollment_id,:assignment_id]
    add_index :turnins, :enrollment_id
    add_index :turnins, :assignment_id

    #users
    rename_column :users, :user_status, :status
    add_index :users, [:date_active, :date_inactive], :name => 'index_users_on_active_dates'
    add_index :users, :coordinator_id
    add_index :users, :privilege
    
  end

  def self.down
  end
end
