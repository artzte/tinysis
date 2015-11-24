class Contract < ActiveRecord::Base

  include StripTagsValidator

  has_many :meetings, :order => "meeting_date", :dependent => :destroy
  has_many :assignments, :order =>  "due_date, CONVERT(name,decimal), name", :dependent => :destroy do

    def weight_total
      sum(:weighting)
    end

    def weight_current
      sum(:weighting, :conditions => 'due_date <= NOW()')
    end

  end

  has_many :enrollments, :include => :participant, :dependent => :destroy do

    # returns a list of statusable enrollments
    def statusable(shallow = false)
      Enrollment.statusable(proxy_association.owner.id, shallow)
    end
  end

  has_many :notes, :as => :notable
  has_many :absences, :through => :enrollments
  has_many :statuses, :through => :enrollments
  belongs_to :facilitator, :foreign_key => 'facilitator_id', :class_name => 'User'
  attr_protected :facilitator

  has_and_belongs_to_many :ealrs, :join_table => 'contract_ealrs'

  belongs_to :category
  belongs_to :term
  belongs_to :creator, :foreign_key => 'creator_id', :class_name => 'User'

  has_many :credit_assignments

  serialize :timeslots, Array

  validates_length_of :name, :within => MIN_TITLE..MAX_TITLE

  validates_presence_of :term,  :message => "must be specified."
  validates_presence_of :category, :message => "must be specified."

  acts_as_textiled :learning_objectives, :competencies, :evaluation_methods, :instructional_materials

  STATUS_PROPOSED = 0
  STATUS_ACTIVE = 1
  STATUS_CLOSED = 2
  STATUS_NAMES = { STATUS_PROPOSED => "Proposed",
    STATUS_ACTIVE => "Approved",
    STATUS_CLOSED => "Closed" }

  def status_name
    STATUS_NAMES[self.contract_status]
  end

  def homeroom?
    category.homeroom?
  end

  def before_save
    self.timeslots ||= []
  end

  def closed?
    self.contract_status==STATUS_CLOSED
  end

  def active?
    self.contract_status==STATUS_ACTIVE
  end

  def activate
    update_attribute(:contract_status, STATUS_ACTIVE)
  end

  def close
    update_attribute(:contract_status, STATUS_CLOSED)
  end

##########################################################################
# Functions for getting and setting associated model objects

  # Return a hash describing privileges of the specified user

  def Contract.privileges(user)

    # new privs object with no grants
    p = TinyPrivileges.new

    # user must be specified
    return p if user.nil?

    # allow create/view privileges if it's at least a student
    p[:create] =
    p[:view] =
    p[:browse] = (user.privilege >= User::PRIVILEGE_STUDENT)

    # edit privileges connote full privs to assign facilitator, set status, etc.
    # which is only staff or above
    p[:edit] = (user.privilege >= User::PRIVILEGE_STAFF)

    return p
  end

  # Return a hash describing privileges of the specified user
  # on this contract

  def privileges(user)

    # if this is being called on an unsaved record, call back
    # to the class privileges.
    return Contract.privileges(user) if @new_record

    # create a new privileges object with no rights
    p = TinyPrivileges.new

    # user must be specified otherwise no privileges
    return p if user.nil?

    # an admin or facilitator has full privileges
    return p.grant_all if user.admin?
    return p.grant_all if facilitator == user

    ##########################################
    # see if the user has an enrollment role here
    user_role = role_of(user)

    ##########################################
    # USER IS NOT ENROLLED
    # if no role, then check for staff privileges
    if user_role.nil?

      # staff members can view and do notes
      case user.privilege
      when User::PRIVILEGE_STAFF
        p[:view] =
        p[:browse] =
        p[:create_note] =
        p[:view_students] =
        p[:view_note] = true

        # any staff member can edit an unsupervised contract
        p[:edit] = unsupervised

      when User::PRIVILEGE_STUDENT

        # if the user is the creator of the contract and no facilitator has
        # been assigned, he gets various privileges

        if unsupervised and (user.id == creator.id)

          p[:browse] =
          p[:view] =
          p[:edit] =
          p[:create_note] =
          p[:view_note] = true

        else

        # browse is the weakest privilege --- you can view minimal contract
        # details if the contract is public
          p[:browse] = (category.public)
        end
      end

      return p
    end

    ##########################################
    # USER IS ENROLLED
    # FOR EDIT PRIVILEGES,
    # user must be the facilitator, or the creator of an unassigned
    # contract
    return p.grant_all if user_role >= Enrollment::ROLE_INSTRUCTOR || (unsupervised && user.id == self.creator_id)

    # FOR VIEW/BROWSE/NOTE PRIVILEGES,
    # user must be enrolled. we have already ascertained that.
    p[:view] =
    p[:browse] =
    p[:create_note] =
    p[:view_note] = true

    # an instructor or supervisor can edit a note / view student info

    p[:view_students] =
    p[:edit_note] =  (user_role >= Enrollment::ROLE_INSTRUCTOR)

    return p
  end

  ##########################################################################
  # How contracts are sorted

  def <=>(contract)

    return category.sequence <=> contract.category.sequence if category.sequence != contract.category.sequence
    return name <=> contract.name
  end

  def copy(params)

    attribs = {}
    attributes.each do |k,v|
      attribs[k] = v if ['name','timeslots','learning_objectives','category_id','evaluation_methods','competencies','location','instructional_materials'].include?(k)
    end
    return nil if Contract.find(:first, :conditions => ["name = ? and term_id = ? and facilitator_id = ?", params[:name], params[:term_id], params[:facilitator_id]])

    c = Contract.new(attribs)
    c.name = params[:name]
    c.facilitator_id = params[:facilitator_id]
    c.term_id = params[:term_id]
    if c.save
      assignments.each do |a|
        c.assignments << Assignment.new(:name => a.name, :description => a.description, :due_date => c.term.months[0], :weighting => a.weighting, :creator_id => c.facilitator_id) if a.active
      end
      ealrs.each do |e|
        c.ealrs << e
      end
      credit_assignments.each do |ca|
        c.credit_assignments << CreditAssignment.new(:credit_id => ca.credit_id, :credit_hours => ca.credit_hours)
      end
    end

    c

  end

  ##########################################################################
  # Functions for getting lists of different types of contracts

  def Contract.catalog(options = {})

    q = []
    q << "SELECT"
    q << "contracts.*,"
    q << "CONCAT(users.first_name, ' ', users.last_name) AS facilitator_name,"
    q << "categories.name AS category_name, terms.name AS term_name,"
    q << "COALESCE(GROUP_CONCAT(CONCAT(credits.course_name,' / ',credit_assignments.credit_hours) ORDER BY credits.course_name SEPARATOR '; '),'None assigned') AS credit_string"
    q << "FROM contracts"
    q << "INNER JOIN terms ON contracts.term_id = terms.id AND contracts.contract_status = #{Contract::STATUS_ACTIVE}"
    q << "INNER JOIN users ON contracts.facilitator_id = users.id"
    q << "INNER JOIN categories ON contracts.category_id = categories.id AND categories.public = 1"
    q << "LEFT JOIN credit_assignments ON credit_assignments.contract_id = contracts.id"
    q << "LEFT JOIN credits ON credits.id = credit_assignments.credit_id"
    q << "WHERE 1"
    q << "AND (terms.id = #{options[:term_id]})" if options[:term_id]
    q << "AND (contracts.facilitator_id = #{options[:facilitator_id]})" if options[:facilitator_id]
    q << "AND (contracts.category_id = #{options[:category_id]})" if options[:category_id]
    q << "GROUP BY contracts.id"
    q << "ORDER BY categories.sequence, contracts.name"

    Contract.find_by_sql(q.join(' '))
  end

  ##########################################################################
  # Months options

  def statusable_months
    case category.statusable
    when Category::STATUSABLE_NONE
      []
    when Category::STATUSABLE_END
      [term.months.last]
    when Category::STATUSABLE_MONTHLY
      term.months
    end
  end

  ##########################################################################
  # Functions for getting various lists of enrollments on a contract

  # get a list of all the students who are active and not already enrolled
  # in this contract

  def users_open_for_enrollment
    User.find_by_sql "select u.* from users u
      where u.status = #{User::STATUS_ACTIVE} and
            u.id not in
              (select e.participant_id from enrollments e where contract_id = #{id})
      order by last_name, first_name;"
  end

  # returns the enrollment record for a user, or nil if the user
  # is not actively enrolled
  def participant_enrollment(user)
    enrollments.find(:first,
      :conditions => ["enrollment_status >= ? and participant_id = ?",
                        Enrollment::STATUS_ENROLLED, user.id])
  end

  # returns the role of the specified active user or nil if none
  def role_of(user)
    return Enrollment::ROLE_FACILITATOR if user == facilitator

    e = participant_enrollment(user)
    return nil if e.nil?
    e.role
  end

  # contract is not assigned to a staff facilitator
  def unsupervised
    facilitator.nil? or facilitator.unassigned?
  end

  # attendance queries

  def attendance_stats

    # get meeting count -- will assign as absent any "missing" records
    meeting_count = meetings.count

    # get the meeting participants with subtotals for each enrollment/participation combo
    mp_subtotals = MeetingParticipant.connection.select_rows(%Q{
      SELECT mp.enrollment_id, mp.participation, COUNT(mp.id) as count FROM meeting_participants mp
      INNER JOIN enrollments e ON e.id = mp.enrollment_id AND e.contract_id = #{id} AND e.completion_status != #{Enrollment::COMPLETION_CANCELED}
      GROUP BY mp.enrollment_id, mp.participation
      ORDER BY mp.enrollment_id
    })

    results = {}

    # setup the hashes for each contract enrollee
    mp_subtotals.each do |row|

      id = row[0].to_i
      participation = row[1].to_i
      count = row[2].to_i
      results[id] ||= Contract.hash_with_default(0)
      results[id][participation] = count

    end

    # second pass through the list to adjust all the absence counts
    results.values.each do |stats|

      total = stats.values.sum
      stats[MeetingParticipant::ABSENT] ||= 0
      stats[MeetingParticipant::ABSENT] += meeting_count - total

    end

    return results

  end

  def self.hash_with_default(default, init = {})
   init.default = default
    init
  end

  def attendance_hash(options = {})

    q = []
    q << "SELECT * FROM meeting_participants"
    q << "INNER JOIN enrollments ON enrollments.id = meeting_participants.enrollment_id"
    q << "INNER JOIN meetings ON meetings.id = meeting_participants.meeting_id" if options[:first] || options[:last]
    q << "WHERE enrollments.contract_id = #{self.id} AND enrollments.completion_status != #{Enrollment::COMPLETION_CANCELED}"
    q << "AND meetings.meeting_date >= '#{options[:first]}'" if options[:first]
    q << "AND meetings.meeting_date <= '#{options[:last]}'" if options[:last]

    participants = MeetingParticipant.find_by_sql(q.join(' '))
    participants = participants.group_by{|p| p.enrollment_id}
    participants.each do |k,v|
      participants[k] = participants[k].group_by{|p| p.meeting_id}
    end
    participants

  end

  def after_initialize

    # set the helper attributes for a contract on add
    self.timeslots ||= [{}]
    #@contract.credits = Credit.empty_credits

    self.contract_status ||= Contract::STATUS_PROPOSED

  end

end
