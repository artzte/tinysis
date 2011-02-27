class GraduationPlanController < ApplicationController

  before_filter :login_required
  before_filter :get_student, :get_graduation_plan
  before_filter :set_meta, :only => [:index, :report, :placeholders]

  helper :credit
  layout 'tiny', :only => [:index, :report, :placeholders]
  
  def index
    @unassigned_credits = my_unassigned
    
    @requirements = GraduationPlanRequirement.requirements_hash 
    
    @credit_requirements = @requirements[:credit]||[]
    @general_requirements = @requirements[:general]||[]
    @service_requirements = @requirements[:service]||[]
    
    @assigned = @graduation_plan.mappings_hash
    
    @report = true unless @privs[:edit]
  end
  
  def report
    index
    @report = true
    render :action => :index
  end

  def placeholders
  end

  def edit
    @mapping = @graduation_plan.graduation_plan_mappings.find params[:mapping_id], :include => :graduation_plan_requirement
    @requirement = @mapping.graduation_plan_requirement
  end

  def new
    @requirement = GraduationPlanRequirement.find params[:requirement_id]
    @mapping = GraduationPlanMapping.new :graduation_plan_requirement_id => @requirement.id
  end

  def create
    @requirement = GraduationPlanRequirement.find params[:mapping][:graduation_plan_requirement_id]
    @mapping = GraduationPlanMapping.new params[:mapping]
    @mapping.graduation_plan_id = @graduation_plan.id

    if @mapping.save
      render :json => [@mapping.id, render_to_string(:partial => "#{@mapping.graduation_plan_requirement.requirement_type}_mapping", :object => @mapping)].to_json
    else
      render :action => 'new'
    end
  end
  
  def show
    @mapping = @graduation_plan.graduation_plan_mappings.find(params[:mapping_id], :include => :graduation_plan_requirement)
    render :partial => "#{@mapping.graduation_plan_requirement.requirement_type}_mapping", :object => @mapping
  end

  def update
    @mapping = @graduation_plan.graduation_plan_mappings.find params[:mapping_id], :include => :graduation_plan_requirement
    if @mapping.update_attributes(params[:mapping])
      render :partial => "#{@mapping.graduation_plan_requirement.requirement_type}_mapping", :object => @mapping
    else
      render :action => 'edit', :status => 500
    end
  end
  
  def assign
    req = GraduationPlanRequirement.find(params[:graduation_requirement_id])
    ca = CreditAssignment.find(params[:credit_assignment_id])
    
    @graduation_plan.map_credit_assignment(req, ca)
    
    hash = @graduation_plan.mappings_hash req
    
    render :partial => 'mapping', :collection => hash[req.id][:mappings]
  end
  
  def unassign
    mapping = @graduation_plan.graduation_plan_mappings.find(params[:mapping_id])
    mapping.destroy

    render :partial => 'unassigned', :collection => my_unassigned
  end

  def destroy
    mapping = @graduation_plan.graduation_plan_mappings.find(params[:mapping_id])
    mapping.destroy

    render :nothing => true
  end
  
protected
  def set_meta
    super :tab1 => :students, :tab2 => :graduation, :title => "#{@student.name} - Graduation Plan"
  end

  def get_graduation_plan
    @graduation_plan = @student.graduation_plan
  end
  
  def my_unassigned
    # (@student.unassigned_credits + @graduation_plan.unassigned_credits).sort{|x,y| x.credit.course_name<=>y.credit.course_name}
    (@student.unassigned_credits).sort{|x,y| x.credit_course_name<=>y.credit_course_name}
  end

end
