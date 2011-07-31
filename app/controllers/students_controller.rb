class StudentsController < ApplicationController
  include ApplicationHelper
  include StudentsSearchHelper
  include StudentReport
  
  helper :note, :status
  
  before_filter :login_required
  before_filter :get_student, :only => [:status]
  before_filter :set_meta, :only => [:index, :status]
  
  def index
  	get_session_pager('student')
  	
  	students_index_init
  	
  	@students = students_find(@fp)
  	setup_page_variables @students, 50
  	
  	store_session_pager('student')
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
  
end
