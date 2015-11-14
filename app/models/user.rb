# There are three status variables for users.
# privilege: 0 = no rights, 1=student rights, 2=staff rights, 3=admin rights
# login_status: 0 == can't login, 1==account requested, 2==can log in
# status: 0 == no status, 1==active, 2==inactive

require "digest/sha2"

class User < ActiveRecord::Base

  before_save :encrypt_password
  before_save :null_inactive_date_if_set_active

	include StripTagsValidator
	include Statusable
	include UnassignedCredits

	PRIVILEGE_NONE = 0
	PRIVILEGE_STUDENT = 1
	PRIVILEGE_STAFF = 2
	PRIVILEGE_ADMIN = 3
	
	PRIVILEGE_NAMES = {
		PRIVILEGE_NONE => "None",
		PRIVILEGE_STUDENT => "Student",
		PRIVILEGE_STAFF => "Staff",
		PRIVILEGE_ADMIN => "Administrator" }
		
	STATUS_BOGUS = 0
	STATUS_ACTIVE = 1
	STATUS_INACTIVE = 2
	
	STATUS_NAMES = {
	  STATUS_BOGUS => "Invalid",
	  STATUS_ACTIVE => "Active",
	  STATUS_INACTIVE => "Inactive"
	}
	
  #####################################################################################
  #
  # SIS object validations etc.
	
	has_many :facilitated_contracts, :class_name => 'Contract', :foreign_key => 'facilitator_id'

	# contracts created under this user's login
	has_many :contracts_created,  :class_name => 'Contract', :foreign_key  =>'creator_id'

	# user enrollments. these are attached to the user through the enrollments
	# table. students are enrolled in classes. they have contracts through the
	# enrollments table.
	has_many :enrollments, :class_name =>'Enrollment', :foreign_key => 'participant_id'

	# the set of classes the student is enrolled in.
	has_many :contracts, :through => :enrollments 
	
	# the turnins for this user
	has_many :turnins, :through => :enrollments

	# can be status'ed
	has_many :statuses, :as => :statusable, :dependent => :destroy, :order => 'month DESC' do 
	  def make(month, user)
	    Status.make(month, proxy_owner, user)
	  end
    def current
      find_by_month Date.today.beginning_of_month
    end
	end
	
	# each year there is a learning plan.
	has_many :learning_plans do
    def current
      find_by_year Setting.current_year
    end
  end
	
	# there is one graduation plan
	has_one :_graduation_plan, :class_name => 'GraduationPlan', :foreign_key => 'user_id'
	
	# has a coordinator
	belongs_to :coordinator, :class_name=>'User', :foreign_key=>'coordinator_id'
	has_many :coordinatees, :class_name=>'User', :foreign_key=>'coordinator_id', :order => 'last_name, first_name'
	
	validates_presence_of :status, :privilege
	validates_presence_of :date_inactive, :if => Proc.new{|user| user.status == User::STATUS_INACTIVE}, :message => 'required if status is INACTIVE'
  validates_presence_of :coordinator, :if => Proc.new{|user| user.privilege == PRIVILEGE_STUDENT}, :message => 'student accounts must have an assigned coordinator.'

  has_many :credit_assignments, :conditions => 'credit_assignments.parent_credit_assignment_id IS NULL'
  has_many :facilitated_credit_assignments, :class_name => 'CreditAssignment', :foreign_key => :contract_facilitator_id

#########################################################
# Helper functions for getting lists of enrollments for
# this user

  def last_name_first

    name = self.last_name + ", " + self.first_name
    name += " (#{self.nickname})" unless self.nickname.blank?
    name

  end

  def full_name

    self.first_name + " " + self.last_name

  end

  def name

    if self.nickname and !self.nickname.empty? 
      self.nickname + ' ' + self.last_name
    else
      self.first_name + ' ' + self.last_name
    end
  end

  def given_name

    unless self.nickname.blank? 
      self.nickname
    else
      self.first_name
    end

  end


  def last_name_f

    "#{self.last_name}, #{self.first_name[0..0]}"

  end

	# Return a hash describing privileges of the specified user
	# on this contract

	def User.privileges(user)
	
		p = TinyPrivileges.new
		
		# user must be specified otherwise no privileges
		return p if user.nil?

		p.grant_all if(user.admin?)

		p
			
	end

  # returns learning plan FTE or 0 if there is no current learning plan
  def fte
    lp = learning_plans.current
    return lp ? lp.weekly_hours : 0
  end

	def privileges(user)

		# if this is being called on an unsaved record, call back
		# to the class privileges.
		return User.privileges(user) if @new_record

		# create a new privileges object with no rights
		p = TinyPrivileges.new

		# user must be specified otherwise no privileges
		return p if user.nil?

		# an admin or the coordinator has full privileges
		return p.grant_all if user.admin?
		return p.grant_all if coordinator_id == user.id
		
		# a staff member can view
		if user.staff?
			
			p[:browse] = 
			p[:view] = 
			p[:create_note] =
			p[:view_note] = true
			
			return p
		
		end
		
		# privileges to grant if this is the logged on user
		if user.id == id and status = STATUS_ACTIVE
			
			p[:browse] = 
			p[:view] = 
			p[:create_note] =
			p[:view_note] = 
			p[:change_settings] = true
			
			return p
		
		end
		
		return p
	end
	
	def admin?
	  self.privilege >= PRIVILEGE_ADMIN
	end

	def staff?
	  self.privilege >= PRIVILEGE_STAFF
	end
	
	def student?
	  self.privilege==PRIVILEGE_STUDENT
	end
	
	def active?
	  self.status == User::STATUS_ACTIVE
  end

  def can_login?
    active? && self.login_status == LOGIN_ALLOWED
  end

	# returns true if the user was active during the indicated month, otherwise returns false.
	
	def was_active?(month)

	  return false if month.end_of_month < self.date_active
	  
	  return true if self.status == STATUS_ACTIVE

    return month <= self.date_inactive
	end

  #########################################################
  # Learning plans

	def learning_plan(year = Setting.current_year)
	
		learning_plans.find(:first, :conditions => "year = #{year}")
	
	end
	
	def graduation_plan
	  if self._graduation_plan
      return self._graduation_plan
    else
      self._graduation_plan = GraduationPlan.create(:user => self)
      self.save
      return self._graduation_plan
    end
  end

  #########################################################
  # Coordinatees

	# returns whether this user is a coordinator
	
	def coor? 
	  coordinatees.length > 0
	end
	
	# returns an array of users who are coordinators. If the passed ID matches
	# a coordinator, the array will only include that user.
	
	def self.coordinators(id = -1)
	  
	  q = <<END
    SELECT users.*, coordinatees.count FROM users
    LEFT JOIN (SELECT coordinatees.coordinator_id, COALESCE(COUNT(coordinatees.id),0) AS count FROM users AS coordinatees GROUP BY coordinatees.coordinator_id) AS coordinatees ON coordinatees.coordinator_id = users.id
    WHERE coordinatees.count IS NOT NULL
    ORDER BY users.last_name, users.first_name	  
END
    User.find_by_sql(q)
	  
	end
	
	# returns an array of coordinatees for this year - students assigned to
	# this coordinator who were active during any of this year's months.
	
	def coordinatees_current(term = nil)
	  term ||= Term.coor
	  coordinatees.find(:all, :conditions => ["(status = #{User::STATUS_ACTIVE}) OR (status = #{User::STATUS_INACTIVE} AND date_active >= ? AND date_inactive <= ?)", term.months.first, term.months.last.end_of_month], :include => [:statuses], :order => 'last_name, first_name')
	end
	
	def self.students(term = nil)
	  term ||= Term.coor
	  User.find(:all, :conditions => ["(status = #{User::STATUS_ACTIVE}) OR (status = #{User::STATUS_INACTIVE} AND date_active >= ? AND date_inactive <= ?)", term.months.first, term.months.last.end_of_month], :include => [:statuses], :order => 'last_name, first_name')
	end
	
  # Enrollments report shows all enrollments for the current school year
  # :school_year => filter by year
  # :fulfilled => true/false to show / not show fulfilled enrollments

	def enrollments_report(options = {})
	  
	  q = []
	  params = []
	  
	  q << "SELECT contracts.name AS contract_name, CONCAT(facilitator.last_name, ', ', facilitator.first_name) AS facilitator_name, terms.name AS term_name, terms.school_year AS term_school_year, terms.credit_date AS term_credit_date, contracts.term_id, COALESCE(GROUP_CONCAT(CONCAT(credits.course_name,' / ',credit_assignments.credit_hours) ORDER BY credits.course_name SEPARATOR '; '),'None assigned') AS credit_string, contracts.timeslots, enrollments.*, assignments.assignments_count FROM enrollments"
    q << "INNER JOIN contracts ON enrollments.contract_id = contracts.id"
    q << "INNER JOIN categories ON contracts.category_id = categories.id"
    q << "INNER JOIN terms ON contracts.term_id = terms.id"
    if options[:school_year]
      q << "AND terms.school_year = ?"
      params << options[:school_year]
    end
    q << "INNER JOIN users AS facilitator ON contracts.facilitator_id = facilitator.id"
    q << "LEFT JOIN (SELECT COUNT(id) AS assignments_count, contract_id FROM assignments WHERE active = true GROUP BY contract_id) AS assignments ON assignments.contract_id = contracts.id"
    q << "LEFT JOIN credit_assignments ON credit_assignments.enrollment_id = enrollments.id"
    q << "LEFT JOIN credits ON credit_assignments.credit_id = credits.id"
    q << "WHERE enrollments.participant_id = #{self.id}"
    case options[:fulfilled]
    when true
      q << "AND enrollments.completion_status = #{Enrollment::COMPLETION_FULFILLED}" 
    when false
      q << "AND enrollments.completion_status != #{Enrollment::COMPLETION_FULFILLED}" 
    end
    case options[:canceled]
    when true
      q << "AND enrollments.completion_status = #{Enrollment::COMPLETION_CANCELED}" 
    when false
      q << "AND enrollments.completion_status != #{Enrollment::COMPLETION_CANCELED}" 
    end
    q << "GROUP BY enrollments.id"
    q << "ORDER BY enrollments.completion_status, term_credit_date DESC, term_name, contract_name"

    enrollments = Enrollment.find_by_sql([q.join(' ')]+params)
    enrollments.each do |e|
      e.timeslots = ClassPeriod.timeslot_strings(YAML::load(e[:timeslots]))
    end
    enrollments

	end
	
  # active enrollments
	def enrollments_active
	  
	  enrollments.find(:all, :conditions => "finalized_on is null and (completion_status != #{Enrollment::COMPLETION_CANCELED})", :include => [{:contract => [:category, :facilitator, :term]}, {:credit_assignments => :credit}, {:statuses => :notes} ], :order => 'contracts.name')
	end
	
	# returns a User object for the phantom unassigned staff member.	

	def User.unassigned
		un = find_by_last_name("Unassigned")
		if un.nil?
			un = User.new
			un.login = "unassigned"
			un.first_name = ""
			un.last_name = "Unassigned"
			un.privilege = PRIVILEGE_STAFF
			un.status = STATUS_ACTIVE
			un.save
		end
		un
	end

	# whether this is an unassigned user id

	def unassigned?
		self.id == User.unassigned.id
	end
	
	# is this user enrolled in a contract?
	
	def enrolled_in? contract
	  Enrollment.count(:conditions => ["contract_id = ? AND participant_id = ? AND completion_status <> ?", contract.id, self.id, Enrollment::COMPLETION_CANCELED]) > 0
	end

	# active staff members

	def User.staff_users
		User.find(:all, 
			:conditions => ["privilege >= ? and status = ?", PRIVILEGE_STAFF, STATUS_ACTIVE],
			:order => "last_name,first_name")
	end
	
	# Staff users with active contracts
	
	def User.teachers
	  User.find_by_sql("SELECT DISTINCT(users.id), last_name, first_name FROM users
	    INNER JOIN contracts ON contracts.facilitator_id = users.id AND contracts.contract_status = #{Contract::STATUS_ACTIVE}
	    ORDER BY users.last_name, users.first_name")
	end
	
	
	# find student names

	def User.find_student_names_like(s)
	
		s = s.gsub(/[^\w\- ]/, '')
		name_like = "#{s}%"
		User.find(:all, :conditions => ["(last_name LIKE ? or first_name like ? or nickname like ?) and privilege = ?", name_like, name_like, name_like, PRIVILEGE_STUDENT], :order => "last_name,first_name")
	end
	
	# Gets enrollments for this user
	
	def query_enrollments(conditions, parameters)
	  raise ArgumentError, "conditions must be an array" unless conditions.is_a? Array
	  raise ArgumentError, "parameters must be an array" unless parameters.is_a? Array

    conditions << "(enrollments.participant_id = ?)"
    parameters << self.id

		Enrollment.find(:all, 
				:conditions => [conditions.join(' and ')] + parameters, 
				:include => [{:contract => :category}], 
				:order => "contracts.name")
	end
	
	# gets a hash of contract status reports, indexed by enrollment ID, for the given user
	
	def enrollment_status_reports(options = {})
	  default_options = {
	    :school_year => Setting.current_year
	  }
	  
	  options = default_options.merge options

	  conditions = []
	  arguments = []

    # set enrollee ID
    conditions << "enrollments.participant_id = ?"
    arguments << self.id

    # set school_year
	  conditions << "terms.school_year = ?"
	  arguments << options[:school_year]
	  
	  q = []
	  q << "SELECT DISTINCT(statuses.id), statuses.* FROM statuses"
    q << "INNER JOIN enrollments ON statusable_id = enrollments.id AND statusable_type = 'Enrollment'"
    q << "INNER JOIN contracts ON enrollments.contract_id = contracts.id"
    q << "INNER JOIN terms ON contracts.term_id = terms.id"
    q << "WHERE ("
    q << conditions.join(') AND (')
	  q << ")"
	  q << "ORDER BY statuses.month"
	  
	  Status.find_by_sql([q.join(' ')]+arguments)
	end
	
	def enrollment_extras
    q = []
    q << "("
    q <<  "SELECT DISTINCT enrollments.id"
    q <<  "FROM enrollments"
    q <<  "INNER JOIN turnins ON enrollments.id = turnins.enrollment_id"
    q <<  "WHERE enrollments.participant_id = IN (?)"
    q << ")"
    q << "UNION"
    q << "("
    q <<  "SELECT DISTINCT enrollments.id"
    q <<  "FROM enrollments"
    q <<  "INNER JOIN absences ON enrollments.id = absences.enrollment_id"
    q <<  "WHERE enrollments.id IN (?)"
    q << ")"
    find_by_sql([q.join(' '), enrollments, enrollments])
	end
	
	
	###################################################################################
	# CREDITS
	
	def unfinalized_credits
	  credit_assignments.find(:all, :conditions => "credit_assignments.credit_transmittal_batch_id is null", :include => [:credit, :child_credit_assignments, :contract_term], :order => 'credits.course_name')
  end

  def finalized_credits
	  credit_assignments.find(:all, :conditions => "credit_assignments.credit_transmittal_batch_id is not null", :include => [:credit, :child_credit_assignments, :contract_term], :order => 'credits.course_name')
  end	
	
  #####################################################################################
  # Password and Login validations and constants

	MINPASSWORDLENGTH = 5
	DEFAULTPASSWORDLENGTH = 6
	MAXPASSWORDLENGTH = 40
  REGEX_EMAIL = /^[a-z][\w\d_\-\.\+]+\@[\w\d\.]+$/i
  REGEX_VALIDLOGIN =  /^[\w\-]{5,40}$/
  REGEX_CLEANLOGIN =  /[^\w\-]/

	validates_presence_of :email, :if => Proc.new { |user| user.can_login? }
	validates_format_of :email, :with => REGEX_EMAIL, :if => Proc.new { |user| !user.email.blank? }
  validates_uniqueness_of :email, :if => Proc.new { |user| !user.email.blank? }

  validates_uniqueness_of :login
  validates_format_of :login, :with => REGEX_VALIDLOGIN, :message => ': please enter a login name at least 5 characters long, consisting only of letters and numbers.'

  validates_presence_of :login_status

	validates_format_of :first_name, :last_name, :with => /^['\.\w\- ()]+$/, :message => ': Please enter a first and last name - it can only have letters, numbers, dashes, spaces, and parentheses.'
	
  attr_accessor :password
  validates_presence_of :password, :if => Proc.new{|user| user.can_login? && (user.password_hash.blank?) }
  validates_length_of :password, :in => User::MINPASSWORDLENGTH..User::MAXPASSWORDLENGTH, :if => Proc.new{|user| user.can_login? && (user.password_hash.blank?)}
  validates_confirmation_of :password

  attr_protected :status, :login_status, :privilege, :coordinator_id, :date_inactive, :date_active

	LOGIN_NONE = 0
	LOGIN_REQUESTED = 1
	LOGIN_ALLOWED = 2
	
	LOGIN_NAMES = {
	  LOGIN_NONE => "No",
	  LOGIN_REQUESTED => "Requested",
	  LOGIN_ALLOWED => "Yes"	  
	}
	
  #########################################################
  #
  # PASSWORD SETTING

	# Encrypts the password attribute and saves the record
  def encrypt_password
    return if self.password.blank?
    self.password_salt = [Array.new(6){rand(256).chr}.join].pack("m").chomp
    self.password_hash = Digest::SHA256.hexdigest(self.password + self.password_salt)
  end

  # resets the password, updating the record
  def reset_password
    plaintext = User.random_password
    self.password = self.password_confirmation = plaintext
    save!
    plaintext
  end

  # generates a semi human readable random password
  def self.random_password(size = DEFAULTPASSWORDLENGTH)
    c = %w(b c d f g h j k l m n p qu r s t v w x z ch cr fr nd ng nk nt ph pr rd sh sl sp st th tr)
    v = %w(a e i o u y)
    f, r = true, ''
    size.times do
      r << (f ? c[rand * c.size] : v[rand * v.size])
      f = !f
    end
    #r.slice(0,size)
    r
  end

  #########################################################
  #
  # LOGIN AND AUTHORIZATION FUNCTIONS

  def self.authorized_email(email)
    find(:first, :conditions => ["email = ? and privilege > ? and login_status = ?", email, User::PRIVILEGE_NONE, User::LOGIN_ALLOWED])
  end


  # generates a unique login name given a last_name, first_name combo
  def User.unique_login(last, first)

    last = String.new(last)
    first = String.new(first)

    [first,last].each{|n| n.gsub!(REGEX_CLEANLOGIN,'')}
    raise ArgumentError, "Invalid characters in name #{first} #{last}" if (last+first).empty?
    for i in (0..first.length-1)
      login = "#{last}#{first[0..i]}".downcase
      next if login.length < MINPASSWORDLENGTH
      return login unless User.find(:first, :conditions => ["login = ?", login])
    end

    # give five more tries before giving up
    for i in (1..5)
      login = "#{last}#{first}#{i}".downcase
      next if login.length < MINPASSWORDLENGTH
      return login unless User.find(:first, :conditions => ["login = ?", login])
    end

    return nil

  end


	# Authenticates a login, password combination and returns the
	# matching user (or NIL)
  def self.authenticate(login, password)
    user = User.find_by_login(login)
    return nil if user.blank? or 
      user.login_status != LOGIN_ALLOWED or 
      user.status != STATUS_ACTIVE or
      user.privilege == PRIVILEGE_NONE or 
      Digest::SHA256.hexdigest(password+user.password_salt) != user.password_hash
    user
  end


  # Update an account record given a parameter set and a user to confirm permissions on
  def update_from_params user_params, user

    raise ArgumentError, "Something wrong with the parameters" unless user_params

		# check the set of protected attributes and deny access if any are changing without required permissions
		raise ArgumentError, "Account record hacking by user #{user.full_name}" if !user.admin? && !(["privilege","status","login_status","coordinator_id","district_id","district_grade","date_active","date_inactive"] & user_params.keys).empty? || !user.staff? && !(["first_name","last_name"] & user_params.keys).empty?

    self.privilege = user_params[:privilege] if user_params[:privilege]
    self.login_status = user_params[:login_status] if user_params[:login_status]
    self.status = user_params[:status] if user_params[:status]
    [:date_active,:date_inactive].each do |a|
      next unless user_params[a] && !user_params[a].strip.blank?
      begin
        self[a] = Date.parse(user_params[a])
      rescue ArgumentError
        self.errors.add a, 'requires a valid date in the format yyyy-mm-dd'
      end
    end
    return false unless self.errors.empty?

	  # if coordinator ID is there change it
    if user_params[:coordinator_id] == "0"
      self.coordinator = nil
    else
      self.coordinator = User.find(user_params[:coordinator_id]) 
    end if user_params[:coordinator_id]

    # clean out these items we just set manually
    [:login_status, :status, :date_inactive, :date_active, :coordinator_id, :privilege].each do |a|
      user_params.delete a
    end

		self.attributes = user_params

    save
  end

  # make sure inactive date is killed if the user has been set active
  def null_inactive_date_if_set_active
    if self.status == STATUS_ACTIVE
      self.date_inactive = nil
    end
  end


  # Update the student roster with a CSV import

  def self.merge_students(csv_file, active_date, inactive_date)
	
    raise(ArgumentError, "specify FILE=filename") unless ENV['FILE']
    raise(ArgumentError, "specify ACTIVE=date") unless ENV['ACTIVE']
    raise(ArgumentError, "specify INACTIVE=date") unless ENV['INACTIVE']

    puts "merging students"

    coor_inactive = User.find(:first, :conditions => ["privilege = ? and last_name = 'Inactive'", User::PRIVILEGE_STAFF])
    coor_bucket = User.find(:first, :conditions => ["privilege = ? and last_name = 'Bucket'", User::PRIVILEGE_STAFF])

    # mark all students inactive first
    User.update_all(["status = ?, coordinator_id = ?", User::STATUS_INACTIVE, coor_inactive.id], ["privilege = ?", User::PRIVILEGE_STUDENT])
    User.update_all(["date_inactive = ?", Time.mktime(2007,7,1)], "date_inactive is null")

    coordinators = {
      '11' => 'Anderson',
      '7' => 'Barth',
      'P2' => 'Bergquist',
      '10' => 'Brown',
      '4' => 'Cherniak',
      '12' => 'Condrea',
      '12' => 'Croft',
      '6' => 'Franklin',
      'P1' => 'McKittrick',
      '5' => 'Merrell',
      '11' => 'Murphy',
      '2' => 'Osborne',
      '1' => 'Park',
      '14' => 'Perry',
      '5' => 'Robertson',
      'B1' => 'Szwaja',
      '3' => 'Winet',
    }

    coordinators.each do |k,v|
      coor = User.find(:first, :conditions => ["privilege >= ? and last_name = ?", User::PRIVILEGE_STAFF, v])
      raise(ArgumentError, "could not find coor #{v}") unless coor
      coordinators[k] = coor
    end
    coordinators.default = coor_bucket

    line = 0
    raise(ArgumentError, "failed to open #{ENV['FILE']}") unless students = File.open(ENV['FILE'])

    FasterCSV.foreach(ENV['FILE']) do |s|
      line += 1
    	unless s.length == 9
    		raise(ArgumentError, "CSV parse failed on line #{line} of students.csv:\nFound: #{s}\nNeeds: last_name,first_name,DistrictID,Gender,Race,DOB,Age,Grade,Homeroom")
    	end

    	last_name = s[0].strip
    	first_name = s[1].strip
    	district_id = s[2].strip
    	district_grade = s[7].strip.to_i
    	homeroom = s[8].strip

    	# try to find by district ID

    	user = User.find_by_district_id district_id
      user ||= User.find_by_last_name_and_first_name last_name, first_name

    	unless user
    	  user = User.new
    	  user.login = User.unique_login(last_name, first_name)
    	  user.password = User.random_password
    	  user.login_status = User::LOGIN_NONE
    	  user.privilege = User::PRIVILEGE_STUDENT

    	  # user active date should be day before first reporting month
    	  user.date_active = Time.mktime(2007,8,31)
    	end

    	# set active new / existing students
  	  user.last_name = last_name
  	  user.first_name = first_name
  	  user.district_id = district_id
  	  user.district_grade = district_grade
  	  user.status = User::STATUS_ACTIVE
  	  user.date_inactive = nil

    	user.coordinator = coordinators[homeroom]
      puts "User #{last_name} line #{line} homeroom #{homeroom} into the bucket" if user.coordinator.last_name == "Bucket"
    	puts "Error saving user #{last_name}, #{first_name}; line #{line}; errors:\n#{user.errors.inspect}" if !user.save
    end
	
	end
	
end
