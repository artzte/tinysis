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
	
end