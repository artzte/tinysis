class AddEnrollmentFinalized < ActiveRecord::Migration
  def self.up
    add_column :enrollments, :finalized_on, :datetime
  end
  
  def self.down
    remove_column :enrollments, :finalized_on
  end
end
