class ConvertCourseIdToString < ActiveRecord::Migration
  def self.up
    change_column :credits, :course_id, :string, :null => false, :default => '0'
  end

  def self.down
    change_column :credits, :course_id, :integer, :default => 0, :null => false
  end
end
