class Term < ActiveRecord::Base

	include StripTagsValidator

	serialize :months, Array

	has_many :contracts
	has_many :contracts_active, :class_name => 'Contract', :foreign_key => 'term_id', :conditions => "contracts.contract_status < #{Contract::STATUS_CLOSED}"
  has_many :contracts_closed, :class_name => 'Contract', :foreign_key => 'term_id', :conditions => "contracts.contract_status = #{Contract::STATUS_CLOSED}"
  has_many :credit_assignments, :class_name => 'CreditAssignment', :foreign_key => 'contract_term_id'
	
	
	validates_length_of :name, :in=>5..50
	
	attr_accessor :base_month
	attr_accessor :end_month

  def school_year_date
    Date.new self.school_year
  end

  def school_year_date= date
    self.school_year= date.year
  end

	def self.month_name(base_month, i)
	  Date::MONTHNAMES[(base_month+i) > 12 ? (base_month+i)%12 : base_month+i]  
	end
	
	# sets months from an array of strings or integers indicating
	# the month number offset
	
	def set_dates(year, m = [])
	  months_array = []
	  m = m.uniq.sort
	  m = m.collect{|i| i.to_i}
	  self.school_year = year.to_i
	  get_reporting_months
	  
	  m.each do |i|
	    month = self.base_month + i
	    year = self.school_year
	    if month > 12
	      year += 1
	      month %= 12
	    end
      months_array << Date.new(year, month, 1)
	  end
	  self.months = months_array
	end
	    
	def reporting_months_options
		month_array = self.months.sort
		month_array.collect{|m| [m.strftime("%b %Y"), m.to_i]}	
	end
	
	def months_bool
	  months_array = []
	  
	  get_reporting_months

    for i in 0..11
			month = self.base_month + i 
      if month > 12
				year = self.school_year + 1
				month = month % 12
			else
				year = self.school_year
			end
			months_array << self.months.include?(Date.new(year, month))
		end
		
		months_array
			  
	end

	def self.all
	  find_by_sql "SELECT terms.*, COALESCE(contracts.contract_count,0) AS contract_count FROM terms
	    LEFT OUTER JOIN (SELECT term_id, COUNT(id) AS contract_count FROM contracts GROUP BY term_id) AS contracts ON contracts.term_id = terms.id
	    ORDER BY terms.active DESC, terms.school_year DESC, terms.credit_date"
	end
	
	def self.active
	  find_all_by_active(true, :order => 'school_year DESC, credit_date ASC')
	end
	
	def self.creditable
	  find :all, :order => 'school_year DESC, credit_date ASC'
	end
	
	def self.enrollments_report
	  q = <<END
	    SELECT 
	      terms.*, 
	      COALESCE(all_enrollments.count,0) AS count, 
	      COALESCE(finalized_enrollments.count,0) AS finalized_count, 
	      (COALESCE(all_enrollments.count,0)-COALESCE(finalized_enrollments.count,0)) AS open_count 
	    FROM terms
      LEFT OUTER JOIN (
        SELECT contracts.term_id, COUNT(enrollments.id) AS count FROM enrollments 
        INNER JOIN contracts ON enrollments.contract_id = contracts.id 
        WHERE enrollments.enrollment_status = 3 
        GROUP BY contracts.term_id) AS finalized_enrollments ON finalized_enrollments.term_id = terms.id
      LEFT OUTER JOIN (
        SELECT contracts.term_id, COUNT(enrollments.id) AS count FROM enrollments 
        INNER JOIN contracts ON enrollments.contract_id = contracts.id 
        GROUP BY contracts.term_id) AS all_enrollments ON all_enrollments.term_id = terms.id
END
	  Term.find_by_sql(q)
  end
	
	def long_name
	  name = "#{self.school_year}: #{self.name}"
	  name << " (inactive)" unless self.active
	  name 
	end
	
	def self.coor(year = nil)
	  year ||= Setting.current_year
	  coor = Term.new(:active => true, :name => "COOR #{year}")
    coor.get_reporting_months
	  month_count = (12-coor.base_month)+coor.end_month
	  coor.set_dates(year, (0..month_count).to_a)
	  coor
	end
	
  def get_reporting_months
    @@reporting_base_month ||= Setting.reporting_base_month
    @@reporting_end_month ||= Setting.reporting_end_month

	  self.base_month ||= @@reporting_base_month
	  self.end_month ||= @@reporting_end_month
  end

end
