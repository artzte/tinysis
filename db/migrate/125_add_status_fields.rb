class AddStatusFields < ActiveRecord::Migration
  def self.up
    add_column :statuses, :met_fte_requirements, :boolean, :default => true
    add_column :statuses, :held_periodic_checkins, :boolean, :default => false
    Status.update_all('met_fte_requirements = true', 'statusable_type = "Enrollment"')
    Status.update_all('held_periodic_checkins = true', 'statusable_type = "User"')
    
    add_index :users, :date_inactive
    add_index :users, :date_active
    add_index :users, :user_status

    add_index :statuses, :statusable_id
    
    add_index :settings, :setting_name

    add_index :credit_assignments, :creditable_id
    add_index :credit_assignments, :creditable_type
    
    rename_column :users, :firstname, :first_name
    rename_column :users, :lastname, :last_name
  end

  def self.down
    remove_column :statuses, :met_fte_requirements
    remove_column :statuses, :held_periodic_checkins

    remove_index :users, :date_inactive
    remove_index :users, :date_active
    remove_index :users, :user_status

    remove_index :statuses, :statusable_id

    remove_index :credit_assignments, :creditable_id
    remove_index :credit_assignments, :creditable_type

    remove_index :settings, :setting_name
    
    rename_column :users, :first_name, :firstname
    rename_column :users, :last_name, :lastname
  end
end
