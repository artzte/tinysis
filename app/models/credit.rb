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
  
	def Credit.all
		find_by_sql "SELECT credits.*, credit_assignments.count AS assignment_count
		  FROM credits
		  LEFT OUTER JOIN (SELECT credit_id, COUNT(id) AS count FROM credit_assignments GROUP BY credit_id) AS credit_assignments ON credit_assignments.credit_id = credits.id
		  ORDER BY course_type, course_name"
	end
	
	def Credit.options(transmittable = false)
	  if transmittable
	    credits = Credit.transmittable_credits
	  else
	    credits = Credit.all
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
end
