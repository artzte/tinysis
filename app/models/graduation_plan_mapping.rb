class GraduationPlanMapping < ActiveRecord::Base

  belongs_to :graduation_plan
  belongs_to :graduation_plan_requirement
  belongs_to :credit_assignment

  validates_presence_of :graduation_plan, :graduation_plan_requirement

  has_many :notes, :as => :notable, :dependent => :destroy

  def before_save
    if credit_assignment
      self.date_completed = credit_assignment.enrollment_finalized_on
    end
  end

  def placeholder?
    false
    # self.credit_assignment && self.credit_assignment.attributes['creditable_type'] == 'GraduationPlan'
  end
end
