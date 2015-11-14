module StudentReport
  
  
  # Creates a @coor_report hash instance variable containing all the data elements you
  # need to show the COOR report. Requires @privs, @user, @student, @this_month
  # variables. 
  
  def setup_coor_report(options = {})

    options[:school_year] ||= session[:school_year]
    options[:editable] ||= true
    @privs ||= @student.privileges @user
    
    coor = Term.coor options[:school_year]
    
    @coor_report = {:editable => false, :school_year => coor.school_year}
    
    @coor_report.update(options)
    
    @coor_report[:months] = coor.months.select{|m| @student.was_active?(m) && m <= @this_month}.sort{|a,b| b<=>a}

    @coor_report[:statuses] = @student.statuses
    @coor_report[:status_notes] = Note.notes_hash(@coor_report[:statuses])

    @coor_report[:enrollments] = @student.enrollments_report(:school_year => coor.school_year)
    @coor_report[:enrollment_notes] = Note.notes_hash(@coor_report[:enrollments])
    @coor_report[:enrollment_statuses] = @student.enrollment_status_reports(:school_year => coor.school_year)
    @coor_report[:enrollment_status_notes] = Note.notes_hash(@coor_report[:enrollment_statuses])
    @coor_report[:enrollment_statuses] = @coor_report[:enrollment_statuses].group_by{|s| s.statusable_id}

    @coor_report[:editable] = options[:editable] && @privs[:edit]
    
    @coor_report[:statuses] = Hash[*@student.statuses.collect{|s| [s.month, s]}.flatten]
  end
  
  
  # request is a hash with the following keys
  # :cl = -1 for any class, or 9|10|11|12 to filter by *current* class
  # :co = -1 for any coordinator, or a positive integer to filter by coordinator's user ID
  # :sy = required school year filter
  # :na = blank for any name, or string to filter by student name fragment
  #
  # students - list of students
  
  def ale_data(request, students)

    months = Term.coor(request[:sy]).months

    return nil if students.empty?

    statuses = Status.find(:all, :conditions => ["statusable_type = 'User' and statusable_id in (?)", students.collect(&:id)])

    return [statuses.group_by(&:statusable_id), months]
  end
  
  def default_credit_hash
    hash = {}
    hash.default = 0
    hash
  end
  
  # students - list of students
  def credits_data(students, options = {})
    
    # generate a students hash - where default returns will be 0
    data = Hash[*students.collect do |s| 
      [s.id, default_credit_hash]
    end.flatten]
    
    current_year = Setting.current_year
    base_month = Setting.reporting_base_month
    
    options[:span] ||= 1
    options[:span] = options[:span].to_i
    
    arguments = {
      :ids => data.keys
    }
    
    years = []
    
    options[:span].times do |i|
      range_start = Date.new(current_year - i, base_month, 1)
      arguments[:range_start] = range_start.to_s
      arguments[:range_end] = (range_start + 1.year - 1.day).to_s
      
      years << range_start.year

      ca = CreditAssignment.nonzero.uncombined.district_finalize_approved.find(:all, 
        :conditions => [%Q{
            user_id IN (:ids) AND
            (credit_assignments.district_finalize_approved_on >= :range_start AND credit_assignments.district_finalize_approved_on <= :range_end)
          }, arguments],
        :select => "credit_assignments.user_id, ROUND(SUM(credit_hours),2) AS total_hours_earned",
        :group => "user_id")

      # merge the values into the hash
      ca.each do |credit|
        data[credit.user_id][current_year - i] = credit.total_hours_earned.to_f
      end
    end
    
    return [data, years.sort]
  end

end