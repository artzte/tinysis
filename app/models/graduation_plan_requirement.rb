class GraduationPlanRequirement < ActiveRecord::Base

  REQUIREMENT_TYPES = [
    :credit,
    :general,
    :service
  ]
  has_many :graduation_plan_mappings, :dependent => :destroy
  has_many :child_requirements, :foreign_key => :parent_id, :class_name => 'GraduationPlanRequirement', :dependent => :destroy
  belongs_to :parent_requirement, :foreign_key => :parent_id, :class_name => 'GraduationPlanRequirement'

  validates_length_of :name, :minimum => 5
  validates_uniqueness_of :name, :scope => :requirement_type

  def privileges(user)

		# create a new privileges object with no rights
		p = TinyPrivileges.new

		# user must be specified and must be an admin
		return p if user.nil? || !user.admin?

		# an admin has full privileges
		return p.grant_all
	end

	def self.requirements_hash options = {}
	  options = {:hide_children => false}.merge(options)
    requirements = find :all, :include => :child_requirements, :conditions => options[:hide_children] ? 'graduation_plan_requirements.parent_id IS NULL' : nil, :order => 'graduation_plan_requirements.position'

    requirements = requirements.grouped_hash(&:requirement_type)
    requirements
  end

end
