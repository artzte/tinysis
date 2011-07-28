module StudentsSearchHelper
  
protected

  def students_index
  
  	@coordinator_selections = [['All coordinators',-1],['Unassigned',-2]]+User.coordinators.collect{|u| [u.last_name_f, u.id]}

  	get_session_pager('student')
  	
  	students_index_init
  	
  	students_find
  	setup_page_variables @students, 20
  	
    @fp = ({:na => @name_filter, :pg => @page, :co=>@coor_filter, :sy=>@school_year_filter, :sc => @class_filter})
    
  	store_session_pager('student')
  	
  end

  def students_index_init
  
    # if a name specified, set students filter to "all"
    unless params[:na].blank?
      @name_filter = params[:na]
    end
    
    # if no coordinator specified, init the coordinator & page to stored or default values
  	if params[:co].blank?
  	  @coor_filter = @fp[:co] || (@user.coor? ? @user.id : -1)
  	else
  	  @coor_filter = params[:co].to_i
  	end
  	
    # school year
  	if params[:sy].blank?
   	  @school_year_filter = @fp[:sy] || coor_term.school_year
  	else
  	  @school_year_filter = params[:sy].to_i
  	end
  	
    # class
  	if params[:cl].blank? || params[:cl] == "-1"
   	  @class_filter = @fp[:cl] || -1
  	else
  	  @class_filter = params[:cl].to_i
  	end
  	
  	# if selections changed, reset the pager variable to 1
  	if @coor_filter != @fp[:co] or @name_filter != @fp[:na] or @school_year_filter != @fp[:sy] or @class_filter != @fp[:sc]
  	  @page = 1
  	end
	
  end

  def students_find
    conditions = ["(users.privilege = #{User::PRIVILEGE_STUDENT}) AND (users.date_inactive IS NULL OR users.date_inactive >= ?) AND (users.date_active <= ?)"]
    arguments = [Date.new(@school_year_filter,coor_term.months.first.month).end_of_month,Date.new(@school_year_filter+1, coor_term.months.last.month)]
    
    if @name_filter
      conditions << "((users.last_name like ?) or (users.first_name like ?) or (users.nickname like ?))"
      3.times{ arguments << "%#{@name_filter}%"}
    end
    
    case @coor_filter
    when -1
      # nothing added for full range
    when -2
      # unassigned
      conditions << "(users.coordinator_id is null)"
    else
      conditions << "(users.coordinator_id = ?)"
      arguments << @coor_filter
    end

    case @class_filter
    when "", -1
    else
      conditions << "(users.district_grade = ?)"
      arguments << @class_filter
    end
    
    @students = User.find(:all, :include => [:coordinator], :conditions => [conditions.join(' and ')]+arguments, :order => 'users.last_name, users.first_name')

  end


end

