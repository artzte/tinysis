class CreateLearningplanPlanGoals < ActiveRecord::Migration
  def self.up
    create_table :learningplan_plan_goals, :id => false do |t|
			t.column :learningplan_id, :integer
      t.column :learningplan_goal_id, :integer
    end
  end

  def self.down
    drop_table :learningplan_plan_goals
  end
end
