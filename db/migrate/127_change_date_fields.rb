class ChangeDateFields < ActiveRecord::Migration
  def self.up
    drop_table :absences
    change_column :assignments, :due_date, :date, :default=>nil
    rename_column :assignments, :created_on, :created_at
    rename_column :assignments, :updated_on, :updated_at
    rename_column :contracts, :created_on, :created_at
    rename_column :contracts, :updated_on, :updated_at

    change_column :credit_assignments, :enrollment_finalized_on, :date, :default=>nil
    change_column :credit_assignments, :district_finalize_approved_on, :date, :default=>nil
    change_column :credit_assignments, :district_transmitted_on, :date, :default=>nil
    
    change_column :credit_transmittal_batches, :finalized_on, :date, :default=>nil
    change_column :credit_transmittal_batches, :transmitted_on, :date, :default=>nil
    
    change_column :ealrs, :version, :date, :default=>nil
    
    change_column :enrollments, :completion_date, :date, :default=>nil
    change_column :enrollments, :finalized_on, :date, :default=>nil
    
    rename_column :enrollments, :created_on, :created_at
    rename_column :enrollments, :updated_on, :updated_at
    
    rename_column :notes, :created_on, :created_at
    rename_column :notes, :updated_on, :updated_at
    
    change_column :statuses, :month, :date, :default=>nil
    rename_column :statuses, :created_on, :created_at
    rename_column :statuses, :updated_on, :updated_at
    
    change_column :terms, :credit_date, :date, :default=>nil
    change_column :users, :date_active, :date, :default=>nil
    change_column :users, :date_inactive, :date, :default=>nil
    
    Term.find(:all).each do |t|
      t.months = t.months.collect{|m| Date.new(m.year, m.month, m.day)}
      t.save!
    end

  end

  def self.down
  end
end
