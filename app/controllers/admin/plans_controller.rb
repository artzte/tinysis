class Admin::PlansController < AdminBaseController

  before_filter :get_requirement, :only => [:show, :edit, :update, :destroy]
  before_filter :set_meta
  helper :note
  
protected  
  def get_requirement
    @requirement = GraduationPlanRequirement.find params[:id]
    unless @requirement
      flash[:notice] = "Could not find that requirement."
      redirect_to graduation_requirements_path
    end
  end
  
  def set_meta
    super :tab1 => :settings, :tab2 => :plans, :title => 'Settings - Graduation Plans'
  end
  
public  
  def index
    @requirements = GraduationPlanRequirement.requirements_hash :hide_children => true
    
    @credit_requirements = @requirements[:credit]
    @general_requirements = @requirements[:general]
    @service_requirements = @requirements[:service]
  end

  def new
    @requirement = GraduationPlanRequirement.new :requirement_type => params[:type]
    @parent_requirement = GraduationPlanRequirement.find(params[:id]) if params[:id]
    
    render :layout => false if request.xhr?
  end

  def edit
    @parent_requirement = @requirement.parent_requirement
    render :layout => false if request.xhr?
  end
  
  def create
    @requirement = GraduationPlanRequirement.new params[:requirement]
    @parent_requirement = GraduationPlanRequirement.find(params[:parent_id]) if params[:parent_id]
    if @requirement.save
      if @parent_requirement
        @parent_requirement.child_requirements << @requirement 
        flash[:notice] = "Thank you for adding the sub-requirement."
        redirect_to edit_plan_requirement_path(@parent_requirement)
      else
        flash[:notice] = "Thank you for adding the requirement. You can now add sub-requirements and/or notes"
        redirect_to plan_requirements_path  
      end
    else
      render :action => 'new'
    end
  end

  def update
    if @requirement.update_attributes params[:requirement]
      if @requirement.parent_requirement
        flash[:notice] = "Thank you for updating the sub-requirement."
        redirect_to edit_plan_requirement_path(@requirement.parent_requirement)
      else
        flash[:notice] = "Thank you for updating the requirement."
        redirect_to plan_requirements_path
      end
    else
      flash[:notice] = "Please review the settings and try again."
      render :action => 'edit'
    end
  end

  def destroy
    @requirement.destroy
    flash[:notice] = "Thank you for removing the graduation requirement."
    redirect_to plan_requirements_path
  end
  
  def sort
    sortables = params[:credit] || params[:general] || params[:service] || []
    sortables.each_with_index do |p,i|
      plan = GraduationPlanRequirement.find(p)
      plan.update_attribute(:position, i)
    end
    render :nothing => true
  end
  
end
