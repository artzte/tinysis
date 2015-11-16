class GraduationPlan < ActiveRecord::Base

  include UnassignedCredits

  has_many :graduation_plan_mappings
  belongs_to :user

  validates_format_of :class_of, :with => /2\d\d\d/, :if => Proc.new{|gp| !gp.class_of.nil?}, :message => 'must be a valid 4-digit year'

  # Returns a mappings hash keyed by requirement_id
  # :type => requirement_type
  # :mappings => array of mappings
  # :subtotal => subtotal of credit hours for the requirement

  def mappings_hash options = {}

    if options[:req]
      reqs = GraduationPlanRequirement.find_all_by_id req.id, :include => :child_requirements
      conditions = ["graduation_plan_requirement_id = ?", options[:req].id]
    else
      reqs = GraduationPlanRequirement.find :all, :include => :child_requirements
      conditions = nil
    end
    reqs = reqs.collect{|r| [r.id, r]}.flatten
    reqs = Hash[*reqs]

    gpm = graduation_plan_mappings.find :all, :conditions => conditions, :include => [{:credit_assignment => :credit}, {:credit_assignment => :contract_term}], :order => 'terms.credit_date, COALESCE(credit_assignments.credit_course_name, credits.course_name), graduation_plan_mappings.date_completed'
    gpm = gpm.grouped_hash(&:graduation_plan_requirement_id)

    # set up the hashes for each requirement
    gpm.each do |k,v|
      gpm[k] = {:type => v.first.graduation_plan_requirement.requirement_type, :mappings => v, :req => reqs[k]}
      case gpm[k][:type]
      when :credit
        gpm[k][:subtotal] = gpm[k][:mappings].inject(0){|sum,mapping| sum+mapping.credit_assignment.credit_hours.to_f}
      when :service
        gpm[k][:subtotal] = gpm[k][:mappings].inject(0){|sum,mapping| sum+mapping.quantity}
      end
    end

    reqs.keys.each{|id| gpm[id] ||= {:type => reqs[id].requirement_type.to_s, :req => reqs[id], :mappings => [], :subtotal => 0}}

    # second pass through to get subtotal sums for parent requirements
    gpm.each do |k,v|
      if(gpm[k][:type]=='credit' && !gpm[k][:req].child_requirements.empty?)
        gpm[k][:subtotal] = gpm[k][:req].child_requirements.inject(gpm[k][:subtotal]){|sum,child_req| sum+gpm[child_req.id][:subtotal]}
      end
    end

    gpm.default = {:mappings => [], :subtotal => 0}

    return gpm
  end

  #SWEEP
  def map_credit_assignment(requirement, ca)
    raise ArgumentError, "Some kind of information leak" unless (ca.user == self.user) || (ca.primary_parent == self)

    ca.graduation_plan_mapping.destroy if ca.graduation_plan_mapping
    mapping = self.graduation_plan_mappings.create(:credit_assignment => ca, :graduation_plan_requirement => requirement)
  end

  def privileges(user)
    return self.user.privileges(user)
  end

end
