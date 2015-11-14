class EnrollmentController < ApplicationController

  helper :credit, :contract

  before_filter :login_required
  before_filter :get_contract, :only => [:index, :create, :new, :reset]

protected

public
  def index
    set_meta :tab1 => :contracts, :tab2 => :enrollments, :title => "#{@contract.name} Enrollments"

    @credit_options = Credit.options
    @enrollments = @contract.enrollments.all
    @enrollment_notes = Note.notes_hash(@enrollments)
    @credit_notes = Note.notes_hash(@enrollments.collect{|c| c.credit_assignments}.flatten)
    if @privs.nil? or !@privs[:view]
      redir_error(TinyException::SECURITYHACK, @user)
      return
    end
  end

  def new

    @enrollees = @contract.users_open_for_enrollment

    render :layout => 'modalbox'

  end

  # enroll the marked students in the contract

  def create
    # must have staff privileges to be here
    if @user.privilege < User::PRIVILEGE_STAFF 
      redir_error(TinyException::NOPRIVILEGES, @user)
      return    
    end

    count = 0

    # enroll students
    params[:user].each do |key, value|

      # get the student
      student = User.find(key.to_i)

      # enroll the student    
      Enrollment.enroll_student(@contract, student, @user, @privs)

      count += 1
    end

    flash[:notice] = "Thank you for enrolling #{count} participants."

    redirect_to enrollments_path(@contract) and return

  rescue TinyException => e
    flash[:notice] = e.message

    redirect_to enrollments_path(@contract) and return
  end

  # updates the enrollment status - using a defined set of commands. The commands
  # that are allowed are depending on the current enrollment status.

  def update
    enrollment = Enrollment.find(params[:id])

    @privs = enrollment.privileges(@user)

    case params[:command]
    when "drop"
      result = enrollment.set_dropped(@user)
      flash[:notice] = "#{enrollment.participant.full_name} was dropped."
      redirect_to enrollments_path(:id => enrollment.contract_id) and return

    when "cancel"
      result = enrollment.set_closed(Enrollment::COMPLETION_CANCELED, @user)
    when "fulfill"
      result = enrollment.set_closed(Enrollment::COMPLETION_FULFILLED, @user)
    when "approve"
      result = enrollment.set_active(@user)
    when "student","instructor"
      enrollment.set_role(params[:command], @user)
    end

    enrollment.reload

    render :partial => 'status_update', :object => enrollment, :locals => {:editable => true}

  rescue TinyException => e
    redir_error(TinyException::SECURITYHACK, @user)
  end

  # resets all the contract's enrollments to the base contract credits.

  def reset

    redir_error(TinyException::SECURITYHACK, @user) and return unless @contract && @privs[:edit]

    @enrollments = @contract.enrollments.all
    count = 0
    @enrollments.each do |e|
      next unless e.enrollment_status < Enrollment::STATUS_CLOSED
      count += 1
      e.inherit_credits
    end
    flash[:notice] = "Active enrollments have been reset to the base credits."

    redirect_to enrollments_path @contract
  end

end
