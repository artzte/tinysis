class Enrollment < ActiveRecord::Base
  
  
  # Enrollments have four possible states. The state transitions are as follows.
  #
  # Proposed - Active, Drop (destroy)
  # Active - Closed (fulfilled), Closed (canceled)
  # Closed - Active, Finalized (fulfilled), Finalized (canceled)
  # Finalized - cannot change state

	belongs_to :participant, :foreign_key => 'participant_id', :class_name => 'User'
	belongs_to :contract, :include => :category
	belongs_to :creator, :foreign_key => 'creator_id', :class_name => 'User'

	has_many :notes, :as => :notable, :dependent => :destroy
	has_many :statuses, :as => :statusable, :dependent => :destroy do
	  def make(month, user)
	    Status.make(month, proxy_owner, user)
	  end
	end
	
	has_many :turnins, :dependent => :destroy, :order => 'assignments.due_date', :include => :assignment do 

	  def weight_total
	    inject(0){|sum, turnin| sum + (turnin.complete? ? turnin.assignment.weighting : 0)}
	  end

	  def weight_current
	    inject(0){|sum, turnin| sum + ((turnin.complete? && turnin.assignment.due_date <= Date.today) ? turnin.assignment.weighting : 0)}
	  end
	  
	  def stats
	    assignments = Assignment.find_by_sql(%{
	      SELECT assignments.due_date, assignments.weighting, IF(turnins.status, assignments.weighting, 0) AS present FROM assignments
        LEFT JOIN turnins ON turnins.assignment_id = assignments.id AND turnins.enrollment_id = #{proxy_owner.id} AND status IN ('complete','late','exceptional')
        WHERE assignments.contract_id = #{proxy_owner.contract_id} AND assignments.active
        ORDER BY due_date
	    })
	    return {} if assignments.empty?

	    today = Date.today
	    due_assignments = assignments.select{|a| a.due_date <= today}

	    points_possible = assignments.inject(0){|sum,assignment| sum + assignment.weighting}
	    current_points_possible = due_assignments.inject(0){|sum,assignment| sum + assignment.weighting}
	    points_completed = assignments.inject(0){|sum,assignment| sum + assignment.present.to_i}
	    current_points_completed = due_assignments.inject(0){|sum,assignment| sum + assignment.present.to_i}

	    {
	      :points_possible => points_possible, 
	      :current_points_possible => current_points_possible, 
	      :points_completed => points_completed, 
	      :current_points_completed => current_points_completed, 
	      :percent_complete => points_possible==0 ? 0 : ((points_completed.to_f / points_possible) * 100),
	      :current_percent_complete => current_points_possible==0 ? 0 : ((current_points_completed.to_f / current_points_possible) * 100),
	    }
	  end
	  
	  def make(assignments = nil)
	    assignments ||= proxy_owner.contract.assignments
	    values = assignments.collect{|a| "(#{proxy_owner.id}, #{a.id}, NOW(), NOW())"}
	    sql = "INSERT IGNORE INTO turnins(enrollment_id, assignment_id, created_at, updated_at) VALUES #{values.join(',')}"
      ActiveRecord::Base.connection.execute(sql)
	  end

	end
	
	has_many :meeting_participants, :dependent => :destroy do 
	  
	  def stats
	    meetings = MeetingParticipant.find_by_sql(%{
	      SELECT participation, COUNT(participation) AS count FROM meeting_participants
	      INNER JOIN meetings ON meeting_participants.meeting_id = meetings.id
	      WHERE enrollment_id = #{proxy_owner.id}
	      GROUP BY participation
	    })
	    return {} if meetings.empty?

	    absences = meetings.detect{|m| m.participation == MeetingParticipant::ABSENT}
	    tardies = meetings.detect{|m| m.participation == MeetingParticipant::TARDY}
	    presents = meetings.detect{|m| m.participation == MeetingParticipant::PRESENT}
	    
	    s = {
	      :absences => absences ? absences.count.to_i : nil,
	      :presents => presents ? presents.count.to_i : nil,
	      :tardies => tardies ? tardies.count.to_i : nil,
	    }
	    
	    return s
	  end
	  
	end
	
  has_many :legacy_credit_assignments, :as => :creditable, :dependent => :destroy

  has_many :credit_assignments, :dependent => :destroy
  
  # so contract timeslots can be set on enrollment report queries
  attr_accessor :timeslots

public
  
	ROLE_STUDENT = 0
	ROLE_INSTRUCTOR = 1
	ROLE_FACILITATOR = 2

	# Name constants for role values
	ROLE_NAMES = { ROLE_STUDENT => "Student",
		ROLE_INSTRUCTOR => "Instructor" }

	# Note, these are in ascending order of accessibility. 
	# Any enrollment_status >= STATUS_ENROLLED indicates accessibility.
	# enrollment requested
	STATUS_PROPOSED = 0

	# enrollment approved
	STATUS_ENROLLED = 1

	# enrollment completed or canceled
	STATUS_CLOSED = 2
	
	# enrollment finalized and off limits to facilitator
	STATUS_FINALIZED = 3

	# Name constants for enrollment_status levels
	STATUS_NAMES = { STATUS_PROPOSED => "Pending",
		STATUS_ENROLLED => "Enrolled",
		STATUS_CLOSED => "Closed",
		STATUS_FINALIZED => "Finalized" }		

	# enrollment not complete yet
	COMPLETION_UNKNOWN = 0

	# student canceled enrollment
	COMPLETION_CANCELED = 1

	# student successfully completed contract
	COMPLETION_FULFILLED = 2

	# name constants for completion types
	COMPLETION_NAMES = { COMPLETION_UNKNOWN => "Incomplete",
		COMPLETION_CANCELED => "Canceled",
		COMPLETION_FULFILLED => "Fulfilled" }
		
		
	# status methods
	
	def canceled?
	  [STATUS_CLOSED, STATUS_FINALIZED].include?(self.enrollment_status) && self.completion_status == COMPLETION_CANCELED
	end
	
	def finalized?
	  self.enrollment_status == STATUS_FINALIZED
	end
	
	def fulfilled?
	  finalized? && self.completion_status == COMPLETION_FULFILLED
	end
	
	
	def status_description
	  if [STATUS_FINALIZED,STATUS_CLOSED].include? self.enrollment_status
	    COMPLETION_NAMES[self.completion_status]
	  else
	    STATUS_NAMES[self.enrollment_status]
	  end
	end		
		
	# activates enrollment

	def set_active(user)
	  
	  # to set active, user must have privileges, AND enrollment must be either proposed or closed, or, if finalized, must have been canceled, not
	  # fulfilled.
	  
		privs = privileges(user)
		unless privs[:edit] && 
		  (
		    [STATUS_PROPOSED, STATUS_CLOSED].include?(self.enrollment_status) || 
		    (self.enrollment_status==STATUS_FINALIZED && self.completion_status==COMPLETION_CANCELED)
		  )
			raise TinyException, TinyException::MESSAGES[TinyException::NOPRIVILEGES]
		end
		
		self.completion_date = nil
		self.completion_status = COMPLETION_UNKNOWN
		self.enrollment_status = STATUS_ENROLLED
		save!
		
		true
	end
	
	
	# destroys the enrollment. 
	# You must have edit privileges, or be a staff member, or be the
	# student who enrolled himself. 
	
	def set_dropped(user)
		privs = privileges(user)

		# check privileges
		unless (self.enrollment_status == STATUS_PROPOSED and (privs[:edit] or user.id == participant.id)) or 
		  (self.enrollment_status == STATUS_CLOSED and privs[:edit])
			raise TinyException, TinyException::MESSAGES[TinyException::NOPRIVILEGES]
		end
		
		destroy 
		true
	end
	
	
	# sets enrollment closed

	def set_closed(completion_status, user, date = Time.now.gmtime)
		privs = privileges(user)
		unless self.enrollment_status == STATUS_ENROLLED and privs[:edit]
			raise TinyException, TinyException::MESSAGES[TinyException::NOPRIVILEGES]
		end
		self.completion_date = date
		self.completion_status = completion_status
		self.enrollment_status = STATUS_CLOSED
		save!
		true
	end
	
	# change to specified role
	def set_role(role, user)
		privs = privileges(user)
		unless privs[:edit]
			raise TinyException, TinyException::MESSAGES[TinyException::NOPRIVILEGES]
		end
		
		case role
		when "student"
	    update_attribute(:role, Enrollment::ROLE_STUDENT)
	  when "instructor"
	    update_attribute(:role, Enrollment::ROLE_INSTRUCTOR)
	  end
	end
	
	def set_finalized(user, date = Time.now.gmtime)
	  return false if self.finalized_on?
	  return false if self.enrollment_status != Enrollment::STATUS_CLOSED

	  unless user.admin?
			raise TinyException, TinyException::MESSAGES[TinyException::NOPRIVILEGES]
		end
		update_attributes(:enrollment_status => STATUS_FINALIZED, :finalized_on => date)

    # if the enrollment was completed fulfilled, link the credit to the student
	  if self.completion_status == COMPLETION_FULFILLED
	    credit_assignments.each do |ca|
  	    ca.enrollment_finalize(participant, date)
  	  end 
    end
    
		return true
	    
	end
	
	# performs a student enrollment, setting the enrollment_status 
	# appropriately depending on the enrolling user's privileges.

	def Enrollment.enroll_student(contract, student, user, privs=nil)

		# Bail out if we can't get authentication
		if user.nil?
			TinyException.raise_exception(TinyException::SECURITYHACK)
		end

		# Bail out if the user is already enrolled
		if (nil != student.enrollments.find(:first, :conditions => "contract_id = #{contract.id}"))
			TinyException.raise_exception(TinyException::ENROLL_DUPLICATE, user) 
		end
		
		# get the privs 
		privs ||= contract.privileges(user)

		# Bail out if the class isn't enrolling and user doesn't have privileges to edit
		# the enrollment
		TinyException.raise_exception(TinyException::ENROLL_UNAVAILABLE, user) unless privs[:edit]

		# Bail out if a student is trying to enroll another student (or staff member)
		TinyException.raise_exception(TinyException::NOPRIVILEGES, user) if (user.privilege < User::PRIVILEGE_STAFF)
		
		# Enroll the student with status PROPOSED if the current user is not the owner of
		# the contract. Otherwise, enroll the student with status ENROLLED.
		Enrollment.enroll_user( contract, student, user, :role => Enrollment::ROLE_STUDENT, :enrollment_status => contract.facilitator_id == user.id ? Enrollment::STATUS_ENROLLED : nil)
	end
	
	def inherit_credits(c = nil)
	  c ||= contract
	  credit_assignments.clear
    credit_assignments << c.credit_assignments.collect{|c| CreditAssignment.new(:credit => c.credit, :credit_hours => c.credit_hours) }
	end

protected

	# This helper function performs the actual enrollment function. All the
	# error checking is already done.

	def Enrollment.enroll_user( contract, participant, user, options )
		e = Enrollment.new(:participant => participant,
 												:creator => user,
												:completion_status => COMPLETION_UNKNOWN)
		e.enrollment_status = options[:enrollment_status] || Enrollment::STATUS_PROPOSED
		e.role = options[:role] || Enrollment::ROLE_STUDENT
		
		e.inherit_credits(contract) unless participant.privilege > User::PRIVILEGE_STUDENT
		
		contract.enrollments << e
		
		contract.activate if contract.closed? 
		  
		return e
	end

public

  def absences
    meeting_participants.find(:all, :conditions => "participation in (#{MeetingParticipant::ABSENT}, #{MeetingParticipant::TARDY})", :include=>[:meeting], :order=>'meetings.meeting_date DESC')
  end

	# returns a friendly status string for the enrollment
	
	def status_text
	  s = Enrollment::STATUS_NAMES[self.enrollment_status]
	  
	  if [Enrollment::STATUS_CLOSED,Enrollment::STATUS_FINALIZED].include? self.enrollment_status
	    s += "-#{Enrollment::COMPLETION_NAMES[self.completion_status]}"
	  end
	  s
	end
	
	# returns an array of friendly credit strings
	
	def credit_strings
	  if credit_assignments.empty? 
	    ["No credits assigned."]
	  else
	    credit_assignments.collect{|c| c.credit_string}
	  end
	end
	
	# Return a hash describing privileges of the specified user

	def Enrollment.privileges(user)

		# new privs object with no grants
		p = TinyPrivileges.new

		# user must be specified
		return p if user.nil?

		# allow creation privileges for students on up
		p[:create] = user.privilege >= User::PRIVILEGE_STUDENT
		return p
	end

	# Return a hash describing privileges of the specified user
	# on this enrollment

	def privileges(user)

		# create a new privileges object with no rights
		p = TinyPrivileges.new

		# user must be specified
		return p if user.nil?

		# an admin has full privileges
		return p.grant_all if user.admin?
		return p.grant_all if user == contract.facilitator

		##########################################
		# see if the user has an enrollment role on the contract here
		user_role = contract.role_of(user)

		##########################################
		# USER IS NOT ENROLLED
		# if no role, then check for staff privileges
		if user_role.nil?

			# staff members can view and do notes
			# non-staff, non-enrolled user has no privileges
			p[:browse] = 
			p[:view] = 
			p[:create_note] = 
			p[:view_students] = 
			p[:view_note] = (user.privilege == User::PRIVILEGE_STAFF)

			return p
		end

		##########################################
		# USER IS ENROLLED
		# FOR EDIT PRIVILEGES,
		# user must be instructor
		p[:edit] = (user_role >= Enrollment::ROLE_INSTRUCTOR)
		
		# FOR VIEW, NOTE PRIVILEGES,
		# user must be an instructor or a supervisor or the enrolled student
		p[:view] = 
		p[:create_note] = 
		p[:view_note] =
		p[:browse] = ((user_role >= Enrollment::ROLE_INSTRUCTOR) or
									(user.id == participant.id))

		# an instructor or supervisor can edit a note
		p[:view_students] =   # bogus since an enrollment only deals with one student
		p[:edit_note] = user_role >= Enrollment::ROLE_INSTRUCTOR
		return p
	end
	
	
	def self.statusable(contract_ids, shallow)
    includes = [:participant]
	  includes += [:contract, :statuses] unless shallow
	  
	  conditions = ["(users.privilege < ?)","(completion_status <> ?)"]
	  parameters = [User::PRIVILEGE_STAFF, Enrollment::COMPLETION_CANCELED]
	  if contract_ids.is_a?(Array)
	    return [] if contract_ids.empty?
	    conditions << "contract_id in (#{contract_ids.join(',')})"
	  else
	    conditions << "contract_id = ?"
	    parameters << contract_ids	    
	  end

		Enrollment.find(:all, :order => "users.last_name, users.nickname, users.first_name", 
			:conditions => [conditions.join(' and ')]+parameters,
			:include =>  includes)
  end
  
  def self.with_extras(enrollments)
    q = []
    q << "("
    q <<  "SELECT DISTINCT enrollments.id"
    q <<  "FROM enrollments"
    q <<  "INNER JOIN turnins ON enrollments.id = turnins.enrollment_id"
    q <<  "WHERE enrollments.id IN (?)"
    q << ")"
    q << "UNION"
    q << "("
    q <<  "SELECT DISTINCT enrollments.id"
    q <<  "FROM enrollments"
    q <<  "INNER JOIN meeting_participants ON enrollments.id = meeting_participants.enrollment_id AND meeting_participants.participation IN (#{MeetingParticipant::ABSENT},#{MeetingParticipant::TARDY})"
    q <<  "WHERE enrollments.id IN (?)"
    q << ")"
    ids = find_by_sql([q.join(' '), enrollments, enrollments])
    ids.collect{|e| e.id}
  	
  end
  
end