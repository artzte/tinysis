class CleanupFields < ActiveRecord::Migration
  def self.up
    remove_column :enrollments, :credits
  end

  def self.down
    add_column :enrollments, :credits, :text
  end
end
