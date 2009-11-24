class CreateLearningplanGoals < ActiveRecord::Migration
  def self.up
    create_table :learningplan_goals do |t|
      t.column :description, :text
			t.column :required, :boolean, :default => false
			t.column :active, :boolean, :default => true
			t.column :position, :integer
    end
  end

  def self.down
    drop_table :learningplan_goals
  end
end
