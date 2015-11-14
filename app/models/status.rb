class Status < ActiveRecord::Base
	belongs_to :author, :foreign_key => 'creator_id', :class_name => 'User'
	belongs_to :statusable, :polymorphic => true
	has_many :notes, :as => :notable
	
	validates_uniqueness_of :month, :scope => [:statusable_id, :statusable_type]

	STATUS_ACCEPTABLE = 0
	STATUS_UNACCEPTABLE = 1
	STATUS_PARTICIPATING = 2
	
	STATUS_NAMES = {
		STATUS_ACCEPTABLE => "Satisfactory",
		STATUS_UNACCEPTABLE => "Unsatisfactory",
		STATUS_PARTICIPATING => "Participating" }
		
	def self.make(month, statusable, user)
	  raise ArgumentError, "Invalid date value for status report" unless month.day == 1
    ActiveRecord::Base.connection.execute("INSERT INTO statuses(month, creator_id, created_at, updated_at, statusable_id, statusable_type, met_fte_requirements) 
        VALUES ('#{month.strftime('%Y-%m-%d')}', #{user.id}, NOW(), NOW(), #{statusable.id}, '#{statusable.class.to_s}', #{statusable.is_a?(Enrollment)?1:'NULL'}) 
        ON DUPLICATE KEY UPDATE updated_at = NOW()")
  end
	  

	def privileges(user)
		return statusable.privileges(user)
	end
	
	def unacceptable?
	  (self.academic_status==Status::STATUS_UNACCEPTABLE) || 
	  (self.attendance_status&&self.attendance_status != STATUS_ACCEPTABLE) || 
	  (self.statusable_type=='User'&&self.held_periodic_checkins==false) || 
	  (self.statusable_type=='Enrollment'&&self.met_fte_requirements==false)
  end

	def self.coor_months_missing(options = {})

    # first create basis of the reports hash - a hash of staff members keyed by
    # user.id, values are hashes keyed by months.

	  staff=User.coordinators
	  return {} if staff.empty?
	  report = Hash[*staff.collect{|v| [v.id,nil]}.flatten]

    options[:coor_term] ||= Term.coor
    term = options[:coor_term]

    now = Date.new(Date.today.year, Date.today.month)

    term_months = term.months.dup
    term_months.reject{|m| m < now}

    report.each do |k,v|
      report[k] = Hash[*term_months.collect{|v| [v,nil]}.flatten]
    end

    # grab a list of students who are active with their coordinator ids
  	students = User.find(:all, :order => "last_name,first_name", :conditions => ["privilege = ? AND (status = ? OR (date_active > ? AND date_inactive <= ?))", User::PRIVILEGE_STUDENT, User::STATUS_ACTIVE,  term.months.first, Time.mktime(term.months.last.year, term.months.last.day).end_of_month])

    # pull the status reports
    q = []
    params = []
    q << "SELECT month, statusable_id, statusees.coordinator_id, CONCAT(coordinators.last_name, ', ', coordinators.first_name) AS coor_name, statusees.date_inactive, statusees.date_active FROM statuses"
    q << "INNER JOIN users AS statusees ON (statuses.statusable_id = statusees.id AND statuses.statusable_type = 'User' AND (statusees.date_inactive IS NULL OR statusees.date_inactive > ?))" 
    q << "INNER JOIN users AS coordinators ON statusees.coordinator_id = coordinators.id"
    if options[:coordinator_id]
      q << "AND coordinators.id = ?"
      params << params[:coordinator_id].to_i
    end
    q << "WHERE statuses.month <= ? AND statuses.month >= ?"
    q << "AND statuses.held_periodic_checkins IS NOT NULL AND statuses.held_periodic_checkins = true"
    q << "ORDER BY coordinator_id, statusable_id, month"

    params << now
    params << term.months.last
    params << term.months.first

    statuses = Status.find_by_sql([q.join(' ')]+params)
    statuses = statuses.group_by{|s| s.statusable_id}

    students.each do |student|
      months = statuses[student.id].blank? ? [] : statuses[student.id].collect{|st| st.month}
      target = term_months.reject{|m| student.date_active > m || (student.date_inactive? && (student.date_inactive < m)) }
      missing = target-months
      missing.each do |m|
        report[student.coordinator_id][m] ||= 1
        report[student.coordinator_id][m] += 1
      end
    end
    report[:coordinators] = staff
    report
	  
	end
	
	# creates a report listing contract status reports missing for a range of 
	# students
	def self.contracts_months_missing(options = {})
    # construct a query to get the list of status reports for the range
    conditions = []
    parameters = []

    if options[:facilitator_id]
      conditions << "contracts.facilitator_id = ?"
      parameters << options[:facilitator_id]
    end

    if options[:school_year]
      conditions << "terms.school_year = ?"
      parameters << options[:school_year]
    end

    if options[:term_id]
      conditions << "terms.id = ?"
      parameters << options[:term_id]
    end

    if options[:category_id]
      conditions << "contracts.category_id = ?"
      parameters << options[:category_id]
    end

    if options[:closed] != 1
      conditions << "contracts.contract_status = ?"
      parameters << Contract::STATUS_ACTIVE
    end

    # grab the set of contracts with the term objects needed to generate the 
    # statusable months list
    unless conditions.empty?
      cond = [conditions.join(' and ')]+parameters
    end
    contracts = Contract.find(:all, :conditions => cond, :include => [:term, :facilitator, :category], :order => 'contracts.name')

    q = []
    q << "SELECT statuses.month, statusable_id FROM statuses"
    q << "INNER JOIN enrollments ON statusable_id = enrollments.id AND statusable_type = 'Enrollment'"
    q << "INNER JOIN contracts ON enrollments.contract_id = contracts.id"
    q << "INNER JOIN terms ON contracts.term_id = terms.id"
    unless conditions.empty?
      q << "WHERE"
      q << conditions.join(' AND ')
    end
    statuses = Status.find_by_sql([q.join(' ')]+parameters )

    # now construct a separate query to get the full enrollments list
    q = []
    q << "SELECT enrollments.id, enrollments.participant_id, contract_id, contracts.name as contract_name FROM enrollments"
    q << "INNER JOIN contracts ON enrollments.contract_id = contracts.id AND enrollments.completion_status <> #{Enrollment::COMPLETION_CANCELED} AND enrollments.role = #{Enrollment::ROLE_STUDENT}"
    q << "INNER JOIN terms ON contracts.term_id = terms.id"
    q << "INNER JOIN users ON enrollments.participant_id = users.id AND users.privilege = #{User::PRIVILEGE_STUDENT}"

    # exclude dropped students
    conditions << "(NOT (enrollments.enrollment_status = #{Enrollment::STATUS_CLOSED} AND enrollments.completion_status = #{Enrollment::COMPLETION_CANCELED}))"
    q << "WHERE "
    q << conditions.join(' AND ')

    enrollments = Enrollment.find_by_sql([q.join(' ')]+parameters )

    # create a hash of status months for each enrollment 
    status_hash = statuses.group_by{|s| s.statusable_id}
    status_hash.keys.each do |i|
      status_hash[i] = status_hash[i].collect{|s| s.month}
    end

    # each contract - construct a report hash
    this_month = Date.today.beginning_of_month
    report = {:contracts=>contracts}
    contracts.each do |c|
      report[c.id] = {}
      report[c.id][:months] = c.statusable_months
      report[c.id][:months].delete_if{|m| m > this_month}

      # create a missing hash with the key being the month - will compile lists under here
      report[c.id][:missing] = Hash[*report[c.id][:months].collect{|m| [m, 0]}.flatten]
    end

    enrollments.each do |enrollment|
      k = enrollment.contract_id
      months_done = status_hash[enrollment.id] || []

      missing = report[k][:months] - months_done

      missing.each do |m|
        report[k][:missing][m] += 1
      end 
    end

    report[:months_range] = contracts.collect{|c| c.term.months}.flatten.uniq.sort
    report
  end

end
