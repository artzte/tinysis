class CreateLearningplans < ActiveRecord::Migration
  def self.up
    create_table :learningplans do |t|
      t.column :user_id, :integer, :null => false
			t.column :year, :integer, :null => false
			t.column :user_goals, :text
			t.column :weekly_hours, :integer, :null => false
    end
  end

  def self.down
    drop_table :learningplans
  end
end
