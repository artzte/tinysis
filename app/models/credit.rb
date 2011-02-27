class Credit < ActiveRecord::Base
  include StripTagsValidator
  
  TYPE_NONE = 0
  TYPE_GENERAL = 1
  TYPE_COURSE = 2
  
  TYPE_NAMES = {
    TYPE_NONE => "None",
    TYPE_GENERAL => "General",
    TYPE_COURSE => "Course" }
    
  validates_presence_of :course_name
  has_many :credit_assignments
  validates_uniqueness_of :course_name, :message => 'has already been used.'
  validates_uniqueness_of :course_id, :if => Proc.new { |cr| cr.course_id.present? and cr.course_id_changed? and cr.course_id != "0" }, :message => 'ID has already been used.'
  
  def Credit.admin_credit_report
    find_by_sql %Q{
      SELECT credits.*, COALESCE(ca_enrolled.count,0) AS enrolled_count, COALESCE(ca_finalized.count,0) AS finalized_count, COALESCE(ca_approved.count,0) AS approved_count
      FROM credits
      
      # credit assignments that are attached to an unfinalized enrollment
      LEFT OUTER JOIN (
        SELECT credit_id, COALESCE(COUNT(id), 0) AS count FROM credit_assignments ca 
          WHERE ca.user_id IS NULL AND ca.enrollment_id IS NOT NULL
          AND ca.enrollment_finalized_on IS NULL
          GROUP BY credit_id) AS ca_enrolled ON ca_enrolled.credit_id = credits.id

      # credit assignments that are finalized and attached to a user record, but not approved by the facilitator
      # excluding children of combined credits, and zero-credits
      LEFT OUTER JOIN (
        SELECT credit_id, COALESCE(COUNT(ca.id), 0) AS count FROM credit_assignments ca
          WHERE ca.user_id IS NOT NULL AND ca.district_finalize_approved_on IS NULL AND ca.parent_credit_assignment_id IS NULL AND ca.credit_hours > 0
          GROUP BY credit_id) AS ca_finalized ON ca_finalized.credit_id = credits.id

      # credit assignments that are approved by the facilitator for transmittal
      LEFT OUTER JOIN (
        SELECT credit_id, COALESCE(COUNT(id), 0) AS count FROM credit_assignments ca 
          WHERE ca.user_id IS NOT NULL AND ca.district_finalize_approved_on IS NOT NULL AND ca.parent_credit_assignment_id IS NULL
          GROUP BY credit_id) AS ca_approved ON ca_approved.credit_id = credits.id

      GROUP BY credits.id
      
      ORDER BY course_type, course_name 
    }
  end
  
  # returns a list of users enrolled in a credit
  def active_enrolled_users_report
    
    User.find :all, 
      :joins => %Q{
        INNER JOIN enrollments e ON e.participant_id = users.id 
        INNER JOIN credit_assignments ca ON ca.enrollment_id = e.id
        INNER JOIN users co ON co.id = users.coordinator_id
        INNER JOIN contracts c ON c.id = e.contract_id
      },
      :conditions => %Q{
        (ca.enrollment_finalized_on IS NULL) AND
        (ca.user_id IS NULL) AND
        (ca.credit_id = #{self.id})
      },
      :select => "users.*, co.last_name AS coordinator_last_name, ca.credit_hours as credit_hours, c.id as enrollment_contract_id",
      :group => 'users.id',
      :order => 'co.last_name ASC, users.last_name ASC'
    
  end
    
  
  # returns a list of users with a finalized but unapproved credit
  def unapproved_credited_users_report
    
    User.find :all, 
      :joins => %Q{
        INNER JOIN enrollments e ON e.participant_id = users.id 
        INNER JOIN credit_assignments ca ON ca.enrollment_id = e.id
        INNER JOIN users co ON co.id = users.coordinator_id
      },
      :conditions => %Q{
        (ca.enrollment_finalized_on IS NOT NULL) AND
        (ca.user_id IS NOT NULL) AND
        (ca.district_finalize_approved_on IS NULL) AND
        (ca.credit_id = #{self.id}) AND
        (ca.parent_credit_assignment_id IS NULL)
      },
      :select => "users.*, co.last_name AS coordinator_last_name, ca.credit_hours as credit_hours, ca.enrollment_finalized_on as enrollment_finalized_on",
      :order => 'co.last_name ASC, users.last_name ASC',
      :group => 'users.id'
    
  end
  
  def Credit.options(transmittable = false)
    if transmittable
      credits = Credit.transmittable_credits
    else
      credits = Credit.find(:all, :order => "course_type, course_name")
    end
    credits.map{|c| [c.credit_string, c.id]}
  end

  def credit_string
    string = self.course_name
    id_string = course_id_string
    string += " (#{course_id_string})" if id_string
    string
  end
  
  def course_id_string
    return '-' unless self.course_id.present? and self.course_id != "0"
    Credit.format_course_id self.course_id
  end
  
  def self.format_course_id course_id
    course_id
  end
  
  def self.transmittable_credits
    find(:all, :order => 'course_name', :conditions => "course_id IS NOT NULL AND NOT course_id IN ('', '0')")
  end
  
  def destroy_credit
    credit_assignments.update_all ["credit_course_name = ?", self.course_name], "credit_course_name IS NULL"
    credit_assignments.update_all ["credit_course_id = ?", self.course_name], "credit_course_id IS NULL"
    
    raise "A credit without denormalized credit info is about to have its credit whacked" if CreditAssignment.find(:first, :conditions => ["(credit_id = ?) AND (enrollment_id IS NOT NULL) AND (credit_course_name IS NULL)", self.id])
    
    destroy
  end
  
end
