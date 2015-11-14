class Admin::LearningPlansController < AdminBaseController

  before_filter :get_goal, :only => [:edit, :update, :destroy]
  before_filter :set_meta

protected  
  def get_goal
    @learning_plan_goal = LearningPlanGoal.find(params[:id])
  end

  def set_meta
    super :tab1 => :settings, :tab2 => :learning_plans, :title => 'Settings - Learning Plans'
  end

public
  def index
  	@learning_plan_goals = LearningPlanGoal.all
  end

  def new
    @learning_plan_goal = LearningPlanGoal.new
  end

  def create
    @learning_plan_goal = LearningPlanGoal.new params[:learning_plan_goal]
    if @learning_plan_goal.save
      flash[:notice] = "Thank you for adding the learning plan goal."
      redirect_to learning_plan_goals_path
    else
      flash[:notice] = "Could not add the learning plan goal. Please check the settings and try again."
      render :action => 'edit'
    end
  end

  def update
    if @learning_plan_goal.update_attributes params[:learning_plan_goal]
      flash[:notice] = "Thank you for updating the learning plan goal."
      redirect_to learning_plan_goals_path
    else
      flash[:notice] = "Could not update the learning plan goal. Please check the settings and try again."
      render :action => 'edit'
    end
  end

  def destroy
    @learning_plan_goal.destroy
    flash[:notice] = "Thank you for deleting the learning plan goal."
    redirect_to learning_plan_goals_path
  end

  def sort
    if params[:goals]
      params[:goals].each_with_index do |goal_id, i|
        goal = LearningPlanGoal.find(goal_id)
        goal.position = i
        goal.save
      end
    end
    render :nothing => true
  end

end
