class CreditAssignment < ActiveRecord::Base
  
  belongs_to :credit
  belongs_to :creditable, :polymorphic => true
  belongs_to :enrollment
  belongs_to :credit_transmittal_batch
  belongs_to :contract_term, :class_name => 'Term', :foreign_key => :contract_term_id
  belongs_to :contract_facilitator, :class_name => 'User', :foreign_key => :contract_facilitator_id
  
	has_many :notes, :as => :notable, :dependent => :destroy
  
	validates_presence_of :credit_id
	belongs_to :parent_credit_assignment, :class_name => 'CreditAssignment', :foreign_key => :parent_credit_assignment_id
	has_many :child_credit_assignments, :class_name  => 'CreditAssignment', :foreign_key => :parent_credit_assignment_id
	
	has_one :graduation_plan_mapping, :dependent => :destroy
	
  def privileges(user)
    creditable.privileges(user)
  end
  
  def placeholder?
    self.creditable_type == 'GraduationPlan'
  end

	def enrollment_finalize(user, date)
	  update_attribute(:enrollment_finalized_on, date)
  end
  
	def district_approve(user, date)
    update_attributes(:district_finalize_approved => true, :district_finalize_approved_by => user.last_name_first, :district_finalize_approved_on => date)
	end
	
	def district_unapprove
	  self.district_finalize_approved = false
	  self.district_finalize_approved_by = nil
	  self.district_finalize_approved_on = nil
	  save!
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
	
	def credit_string
	  str = credit.course_name
	  if credit.course_id.present? and credit.course_id != "0"
	    str += " (#{sprintf('%04d', credit.course_id)})"
	  end
	  str += " / #{credit_hours_string}"
	  str
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
	
	def self.approved_for_transmittal
	  
	  self.find(:all, :include => [:credit], :conditions => "credit_transmittal_batch_id is null and creditable_type = 'User' and district_finalize_approved = true")
	  
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
      ca.save
    end
    student.credit_assignments << parent
	end

	def uncombine
    child_credit_assignments.each do |ca|
      ca.parent_credit_assignment = nil
      ca.save
    end
    destroy
	end
	
end

