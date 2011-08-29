class AttendanceController < ApplicationController

  helper :note, :search, :contract

	before_filter :login_required
	before_filter :get_contract, :only => [:index, :roll]
	
	def index
	  redirect_to contracts_path and return unless @contract
    
    set_meta :title => "#{@contract.name} - Attendance", :tab1 => :contracts, :tab2 => :attendance
	  
	  @meetings = @contract.meetings.find(:all, :order=>'meeting_date DESC')
	  
	  if params[:meeting_id] && params[:pg].nil?
	    @meeting = @contract.meetings.find(params[:meeting_id]) 
	    params[:i] = @meetings.index(@meeting)
	  end
	  
	  setup_page_variables @meetings, 10
	  
	  @stats = @contract.attendance_stats
	  
	  @meeting_dates = @page_items.collect{|m| m.meeting_date}
	  
	  unless @page_items.blank?
	    @meeting_participants = @contract.attendance_hash(:last=>@page_items.first.meeting_date, :first=>@page_items.last.meeting_date)
    else
      @meeting_participants = []
    end
	end
	
	def roll
	  redirect_to contracts_path and return unless @contract

		if !@privs[:view_students]
			redir_error(TinyException::SECURITYHACK, @user)
			return
		end
		
		if params[:meeting_id]
		  @meeting = @contract.meetings.find(params[:meeting_id])
		else
		  date = Date.new(params[:year].to_i, params[:month].to_i, params[:day].to_i)
		  @meeting = @contract.meetings.find_by_meeting_date(date)
		  unless @meeting
		    @meeting = Meeting.new(:meeting_date => date)
		    @contract.meetings << @meeting
		  end
		end
		  
    set_meta :title => "#{@contract.name} - Attendance - #{@meeting.meeting_date.strftime(FORMAT_DATE)}", :tab1 => :contracts, :tab2 => :attendance

		@enrollments = @contract.enrollments.statusable(true)
		@meeting_participants = @meeting.meeting_participants
		@notes_hash = Note.notes_hash(@meeting_participants)
		@meeting_participants_hash = @meeting_participants.index_by(&:enrollment_id)
	end
	

	def delete_roll
	  @meeting = Meeting.find(params[:id], :include => [:contract])
	  privs = @meeting.contract.privileges(@user) if @meeting
	  redirect_to :controller => 'contract' and return unless @meeting && privs[:edit]
	  
	  contract_id = @meeting.contract_id
	  
	  @meeting.destroy
	  
	  flash[:notice] = "The attendance roll was removed."
	  
	  redirect_to attendance_path(:id => contract_id)
	end
	
	def pick_roll
	  if params[:meeting_id]
	    @meeting = Meeting.find(params[:meeting_id], :include => :contract)
	    @contract = @meeting.contract
	  else
	    @contract = Contract.find(params[:id])
	  end
	  @meetings = @contract.meetings
	  @meeting_dates = @meetings.collect{|m| m.meeting_date}

	  render :template => '/attendance/calendar_form', :layout => false
	end
	
	# shows a calendar
	def show_calendar
	  @year = params[:year].to_i if params[:year]
	  @month = params[:month].to_i if params[:month]
	  
	  now = Time.now
	  @year ||= now.year
	  @month ||= now.month
	  
	  @contract = Contract.find(params[:id])
	  @meeting = Meeting.find(params[:meeting_id]) if params[:meeting_id]
    @meetings = @contract.meetings
    @meeting_dates = @meetings.collect{|m| m.meeting_date}
    render :partial => 'calendar'
	end

	# saves the attendance status
	def update
	  
	  @enrollment = Enrollment.find(params[:enrollment_id], :include => :contract)
	  @meeting = Meeting.find(params[:meeting_id])
	  if @enrollment
	    privs = @enrollment.contract.privileges(@user)
	    render :text => "You don't have privileges to do this.", :status=>500 and return unless privs[:edit]
	    
	    participant = update_attendance_for_enrollment(@meeting, @enrollment, params)
	  end
    
    render :json => {:id => participant.id}.to_json
	end
	
	# updates all participants
	def update_all
 
	  @meeting = Meeting.find(params[:id], :include => [:contract])
	  if @meeting
	    privs = @meeting.contract.privileges(@user)
	    render :text => "You don't have privileges to do this.", :status=>500 and return unless privs[:edit]
 
	    @meeting.contract.enrollments.statusable.each do |enrollment|
	      update_attendance_for_enrollment(@meeting, enrollment, params)
	    end
	  end
    flash[:notice] = "Thanks for updating attendance."
    redirect_to roll_path(@meeting.contract_id, @meeting.meeting_date.year, @meeting.meeting_date.month, @meeting.meeting_date.day)
	end

protected
  def update_attendance_for_enrollment(meeting, enrollment, params)
    participant = MeetingParticipant.find_or_create_by_enrollment_id_and_meeting_id(enrollment.id, meeting.id)
    participant.update_attributes(:participation => params[:participation], :contact_type => params[:contact])
    return participant
	end
end
