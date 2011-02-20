class LearningPlanController < ApplicationController

  helper :note
  
  before_filter :get_student
  before_filter :get_lp, :except => [:show, :edit]
  before_filter :lp_meta
  
  def show
    learning_plans = @student.learning_plans
    
    @year = year_from_params
    
    # get complete range of years from start to current regardless of whether there are
    # plans for that year

    @year_options = learning_plans.collect{|p| p.year} + [Setting.current_year]
    @year_options = @year_options.uniq.sort
    @year_options = (@year_options.first..@year_options.last).to_a
    @year_options = @year_options.reverse
    
		@plan = learning_plans.detect{|p| p.year==@year}

		@goals = @plan.learning_plan_goals.collect{|g| g.id} if @plan
		@enrollments = @student.enrollments_report(:school_year => @year)

		@active_enrollments = @enrollments.select{|e| e.enrollment_status != Enrollment::STATUS_FINALIZED}
		@finalized_enrollments = @enrollments.select{|e| e.enrollment_status == Enrollment::STATUS_FINALIZED}

		@active_terms = @active_enrollments.group_by{|e| Term.find(e.term_id)}
		@finalized_terms = @finalized_enrollments.group_by{|e| Term.find(e.term_id)}
  end

  def edit
    @year = year_from_params
    @plan = @student.learning_plan(@year) || @student.learning_plans.create(:year => @year, :weekly_hours => AppConfig.fte_hours)
		@goals = @plan.learning_plan_goals
  end

  def update
		@plan.learning_plan_goals.clear
		
    @plan.learning_plan_goals += LearningPlanGoal.required
    
		params[:goal].each do |k,v|
		  @plan.learning_plan_goals << LearningPlanGoal.find(k)
		end if params[:goal]

		if @plan.update_attributes(params[:plan])
		  flash[:notice] = "Learning plan saved"
		  redirect_to learning_path(@student)
		else
		  edit
		  render :action => 'edit'
		end
  end
  
protected
  def get_lp
    @plan = @student.learning_plan
  end
  
  def lp_meta
    set_meta :tab1 => :students, :tab2 => :learning, :title => "#{@student.full_name} - Learning Plan"
  end
  
  def year_from_params
    params[:year]=='current' ? Setting.current_year : params[:year].to_i
  end
end
