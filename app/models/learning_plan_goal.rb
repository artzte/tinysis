class LearningPlanGoal < ActiveRecord::Base
  include StripTagsValidator

  has_and_belongs_to_many :learning_plans, :join_table => 'learning_plans_to_goals'
  validates_length_of :description, :minimum => 10

  def self.all
    find_by_sql "SELECT learning_plan_goals.*, COALESCE(plans.count,0) AS plans_count
      FROM learning_plan_goals
      LEFT OUTER JOIN (SELECT learning_plans_to_goals.learning_plan_goal_id, COUNT(learning_plan_id) AS count FROM learning_plans_to_goals GROUP BY learning_plan_goal_id) AS plans ON plans.learning_plan_goal_id = learning_plan_goals.id
      ORDER BY active DESC, position"
  end

  def self.required
    find(:all, :conditions => "required = true and active = true", :order => "active DESC, required DESC, position")
  end

  def self.optional
    find(:all, :conditions => "required = false and active = true", :order => "active DESC, required DESC, position")
  end

end
