class CreditAssignment < ActiveRecord::Base

  attr_accessible :credit, :credit_hours

  belongs_to :credit
  belongs_to :legacy_creditable, :polymorphic => true

  belongs_to :enrollment
  belongs_to :user
  belongs_to :contract

  belongs_to :credit_transmittal_batch
  belongs_to :contract_term, :class_name => 'Term', :foreign_key => :contract_term_id
  belongs_to :contract_facilitator, :class_name => 'User', :foreign_key => :contract_facilitator_id

  has_many :notes, :as => :notable, :dependent => :destroy

  validates_presence_of :credit_id
  belongs_to :parent_credit_assignment, :class_name => 'CreditAssignment', :foreign_key => :parent_credit_assignment_id
  has_many :child_credit_assignments, :class_name  => 'CreditAssignment', :foreign_key => :parent_credit_assignment_id

  has_one :graduation_plan_mapping, :dependent => :destroy

  scope :user, :conditions => "user_id IS NOT NULL"
  scope :nonzero, :conditions => "credit_hours > 0"
  scope :uncombined, :conditions => "parent_credit_assignment_id IS NULL"
  scope :district_finalize_approved, :conditions => "district_finalize_approved_on IS NOT NULL"

  def privileges(user)
    primary_parent.privileges(user)
  end

  def placeholder?
    false #self.creditable_type == 'GraduationPlan'
  end

  def assign_credit(user, new_credit)
    raise "User does not have privileges to assign credit" unless privileges(user)[:edit]
    raise "Credit is off limits" if batched_for_transmit?

    self.credit = new_credit
    save

    district_unapprove if coordinator_approved?
  end

  def enrollment_finalize(completion_status, participant, contract, date)
    # set finalized_on date
    self.enrollment_finalized_on = date

    # set denormalized contract values
    self.contract_name = contract.name
    self.contract_facilitator_name = contract.facilitator.last_name_first
    self.contract_facilitator_id = contract.facilitator_id
    self.contract_term_id = contract.term_id

    # assign to student if fulfilled
    case completion_status
    when Enrollment::COMPLETION_FULFILLED
      self.user_id = participant.id

    # cache the credit in case this is a left-behind
    when Enrollment::COMPLETION_CANCELED
      denormalize_credit
    end
    save!
  end

  def enrollment_unfinalize
    raise "Trying to unfinalize a credit that has already passed to the user" if self.user_id?
    self.normalize_credit
    self.enrollment_finalized_on = nil
    save!
  end

  def normalize_credit
    return false unless self.credit_id

    self.credit_course_name = nil
    self.credit_course_id = nil

    return true
  end

  def denormalize_credit
    return false unless self.credit_id

    self.credit_course_name = credit.course_name
    self.credit_course_id = credit.course_id

    return true
  end

  # facilitator has approved the credit for transmittal to the district.
  # move the credit course names over and record who approved the credit for transmittal to district
  def district_approve(user, date)
    raise "Can't approve this, as it has already been approved for recording at the district" if self.credit_transmittal_batch_id

    self.district_finalize_approved = true
    self.district_finalize_approved_by = user.last_name_first
    self.district_finalize_approved_on = date

    # set denormalized credits info
    denormalize_credit

    save!

    self.child_credit_assignments.each do |ca|
      if ca.denormalize_credit
        ca.save
      end
    end
  end

  # safe retrieval of contract term name
  def contract_term_name
    unless self.contract_term_id and self.contract_term
      return 'Unknown term'
    end
    return self.contract_term.name
  end

  def district_unapprove
    raise "Can't unapprove this, as it has already been approved for recording at the district" if self.credit_transmittal_batch_id
    self.district_finalize_approved = false
    self.district_finalize_approved_by = nil
    self.district_finalize_approved_on = nil

    # ensure a credit
    self.credit = Credit.find(:first) unless self.credit

    normalize_credit

    save!

    self.child_credit_assignments.each do |ca|
      if ca.normalize_credit
        ca.save
      end
    end
  end

  def facilitator_approved?
    self.enrollment_finalized_on.nil? == false
  end

  def coordinator_approved?
    self.district_finalize_approved_on.nil? == false
  end

  def batched_for_transmit?
    self.credit_transmittal_batch_id.nil? == false
  end

  def transmitted?
    self.district_transmitted_on?
  end

  # safely retrieve the course ID
  def credit_course_id
    if self.attributes["credit_course_id"].present?
      return self.attributes["credit_course_id"]
    elsif self.credit_id?
      return self.credit.course_id
    else
      raise "No course ID available"
    end
  end

  # safely retrieve the course name
  def credit_course_name
    if self.attributes["credit_course_name"].present?
      return self.attributes["credit_course_name"]
    elsif self.credit_id?
      return self.credit.course_name
    else
      raise "No course name available"
    end

  end

  # credit_course_name
  # credit_course_id
  #
  def credit_string
    "#{credit_course_name} (#{credit_course_id}) / #{credit_hours_string}"
  end

  def credit_hours_string
    if self.override_hours
      "#{self.override_hours} (O:#{self.override_by})"
    else
      self.credit_hours.to_s
    end
  end

  def credits
    self.override_hours || self.credit_hours
  end

  def override(override, user)
    if override.blank?
      self.override_hours = nil
      self.override_by = nil
    else
      self.override_hours = override
      self.override_by = user.last_name_f
    end
  end

  def self.combine(student, credit_id, term_id, override, credit_assignments, user)
    ca_term = credit_assignments[0]

    # scan and get the most recent term and the cumulative hours
    hours = credit_assignments.sum(&:credit_hours)

    # create the new credit
    now = Time.now.gmtime
    year = Setting.current_year

    parent = CreditAssignment.new(:credit_id => credit_id, :credit_hours => hours, :contract_name => "Combined", :contract_facilitator_id => user.id, :contract_facilitator_name => user.last_name_first, :enrollment_finalized_on => now, :contract_term => Term.find_by_id(term_id))
    parent.override(override, user)

    credit_assignments.each do |ca|
      ca.graduation_plan_mapping.destroy if ca.graduation_plan_mapping
      ca.parent_credit_assignment = parent
      ca.denormalize_credit
      ca.save
    end
    student.credit_assignments << parent
  end

  def uncombine
    child_credit_assignments.each do |ca|
      ca.parent_credit_assignment = nil
      ca.normalize_credit
      ca.save
    end
    destroy
  end

  def user?
    self.user_id?
  end

  def primary_parent
    if user?
      return self.user
    elsif self.contract_id?
      return self.contract
    elsif self.enrollment_id?
      return self.enrollment
    else
      raise "Unknown primary parent"
    end
  end

end
