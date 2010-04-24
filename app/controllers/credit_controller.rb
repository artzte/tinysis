require 'helpers/credit_helper'
class CreditController < ApplicationController

	include CreditHelper
	
	before_filter :login_required
	before_filter :get_student, :only => [:index, :combine, :combiner, :admin_destroy]

  def index
    set_meta :tab1 => :students, :tab2 => :credits, :title => "#{@student.name} - Credits Worksheet"

    @credit_assignments = @student.unfinalized_credits

    @finalized_credit_assignments = @student.finalized_credits

    @credit_notes = Note.notes_hash(@credit_assignments+@finalized_credit_assignments)
  end

	# displays the add credit form
	def editor
	  
	  if params[:parent_type]
	    @parent_class = params[:parent_type]
	    @parent_id = params[:parent_id]
	    @parent = eval(@parent_class).find(@parent_id)

  	  @credit = CreditAssignment.new(:credit => Credit.find(:first, :conditions => "course_type = 0"), :credit_hours => 0.5)
  	  @add = true
	  else
	    @credit = CreditAssignment.find(params[:id])
	    @parent = @credit.creditable
	  end
	  
	  @privs = @parent.privileges(@user)
    return redir_error(TinyException::SECURITYHACK, @user) unless @privs[:edit]

	  if @parent.is_a?(User)
	    current_year = Setting.current_year
	    @title = @parent.last_name_f
	    @credit_options = Credit.options(true)
	    render :partial => "worksheet_form"
	  elsif @parent.is_a?(Contract)
	    @title = @parent.name
	    @credit_options = Credit.options
	    render :partial => "credit_form"
	  elsif @parent.is_a?(Enrollment)
	    @title = @parent.participant.last_name_f
	    @credit_options = Credit.options
	    render :partial => "credit_form"
	  elsif @parent.is_a?(GraduationPlan)
	    @title = @parent.user.last_name_f
	    @credit_options = Credit.options
	    render :partial => "placeholder_form"
	  end
	end
	
	def add
	  @parent_type = eval(params[:parent_type])
	  @parent_id = params[:parent_id]
	  
	  @parent = @parent_type.find(@parent_id)
	  @privs = @parent.privileges(@user)
    return redir_error(TinyException::SECURITYHACK, @user) unless @privs[:edit]
	  
	  course = Credit.find(params[:course])
	  credits = params[:credits]
	  
	  credit = CreditAssignment.create(:credit => course, :credit_hours => credits, :contract_term_id => params[:term])
	  @parent.credit_assignments << credit
	  
	  unless params[:notes].blank?
	    credit.notes << Note.new(:note => params[:notes].strip, :author => @user)
	  end
	  
	  render :update do |page|
	    page.replace credit_container_id(@parent), :partial => 'credit/credits', :object => @parent	    
	  end
	end
	
	def update
	  @credit = CreditAssignment.find(params[:id])

	  @parent = @credit.creditable
	  @privs = @credit.privileges(@user)
    return redir_error(TinyException::SECURITYHACK, @user) unless @privs[:edit]

	  # set the hours if they are passed
	  @credit.credit_hours = params[:credits] unless params[:credits].blank?
	  
	  # if override hours passed, set them, otherwise clear override
	  @credit.override params[:credits_override], @user
	  
	  @credit.contract_term = Term.find(params[:term]) if params[:term]
	  @credit.credit = Credit.find(params[:course])
	  @credit.contract_name = @credit.credit.course_name if @parent.is_a? GraduationPlan
	  @credit.save!
	  
	  if @parent.is_a?(User)
	    render :partial => 'credit/credits', :object => @credit, :locals => {:expanded => true, :closed=>false}
	  else
	    render :partial => 'credit/credits', :object => @parent
	  end
	end
	
  def combiner
    
    # split and rejoin credit numbers just to validate
    ca = (params[:c]||'').split(',')
    render :nothing => true and return if ca.length < 2
        
    @title = @student.last_name_f
    @term_options = Term.find(:all).collect{|t| [t.name, t.id]}

    @credit_assignments = @student.credit_assignments.find(:all, :conditions => ["id in (?)", ca])
    hours = 0
    
    # use original hours to calculate, not the override hours
    @credit_assignments.each{|c| hours += c.credit_hours }
    
    @credit_options = Credit.transmittable_credits.collect{|c| [c.credit_string, c.id]}
	  @credit = CreditAssignment.new(:credit_hours => hours)
	  
	  render :partial => 'combine_form', :layout => false
  end
  
  def combine
    ca = params[:c]||[]
    
    raise ArgumentError, "No credits submittted to combine" and return unless ca.length>=2

    @credit_assignments = @student.credit_assignments.find(:all, :conditions => ["id in (?)", ca])

    CreditAssignment.combine(@student, params[:course], params[:term], params[:credits_override], @credit_assignments, @user)

    redirect_to credit_assignments_path(@student)    
  end
  
	# removes a credit from the parent
	
	def destroy
	  @credit = CreditAssignment.find(params[:id])
	  @parent = @credit.creditable
	  
	  @privs = @credit.privileges(@user)
	  return redir_error(TinyException::SECURITYHACK, @user) unless @privs[:edit]
    
	  @credit.destroy
	  
	  render :partial => 'credit/credits', :object => @parent	    
	end

  # Deletes one or more finalized credits from the worksheet
  def admin_destroy
    return redir_error(TinyException::SECURITYHACK, @user) unless @user.admin?
    
    if params[:c]
      @credit_assignments = @student.credit_assignments.find(:all, :conditions => "id in (#{params[:c]})")
      @credit_assignments.each do |ca|
        ca.destroy
      end
    end

    @credit_assignments = @student.unfinalized_credits

    flash[:notice] = "The credits were deleted."
    
    redirect_to credit_assignments_path(@student) 
  end
  
  def split
    
    @credit_assignment = CreditAssignment.find(params[:id])
    @student = @credit_assignment.creditable
    @privs = @student.privileges(@user)
    
    return redir_error(TinyException::SECURITYHACK, @user) unless @student.is_a? User and @privs[:edit]

    @credit_assignment.uncombine
    
    @credit_assignments = @student.unfinalized_credits
    
    redirect_to credit_assignments_path(@student)    
  end
  
  def approve
    credit_assignment = CreditAssignment.find(params[:id])
    @privs = credit_assignment.privileges(@user)
    return redir_error(TinyException::SECURITYHACK, @user) unless @privs[:edit]

    now = Time.now.gmtime
    if params[:v] == "1"
      credit_assignment.district_approve(@user, now)
    else
      credit_assignment.district_unapprove
    end
    render :nothing => true
  end

  
	
end
