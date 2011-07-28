class StudentsController < ApplicationController
  include ApplicationHelper
  include StudentsSearchHelper
  include StudentReport
  
  helper :note, :status
  
  before_filter :login_required
  before_filter :get_student, :only => [:status]
  before_filter :set_meta, :only => [:index, :status]
  
  def index
    students_index
  end
  
  def my
    
    set_meta :tab1 => :my, :tab2 => :summary, :title => @user.full_name
    render :text => 'My status page', :layout => true
    
    
  end
  
  def status
    
    # get a list of school years to which terms are assigned
    @term_years = Term.find_by_sql('SELECT DISTINCT school_year FROM terms ORDER BY school_year DESC')
		@this_year = coor_term.school_year
		
		# construct filter and options for year dropdown
		@year_options = @term_years.collect{|t| ["#{t.school_year} status",t.school_year]}
		@year_filter = params[:year] && params[:year]!='current' ? params[:year].to_i : @this_year 

		setup_coor_report :school_year => @year_filter, :editable => false

    set_meta :title => @student.name
  end
  
protected
  def ale_data(all_statuses = false)
    
    
    if @school_year_filter == coor_term.school_year
      @term = coor_term
    else
      @term = Term.coor(@school_year_filter)
    end
    @months = @term.months
        
    return if @students.empty?
    
    if all_statuses
      statuses = @students
    else
      statuses = @page_items
    end
    
    @statuses = Status.find(:all, :conditions => "statusable_type = 'User' and statusable_id in (#{statuses.collect{|s| s.id}.join(',')})")

    @statuses = @statuses.group_by{|s| s.statusable_id}
  end
  
end
