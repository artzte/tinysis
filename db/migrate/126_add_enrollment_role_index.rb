class AddEnrollmentRoleIndex < ActiveRecord::Migration
  def self.up
    add_index :enrollments, :role
  end

  def self.down
    remove_index :enrollments, :role
  end
end
