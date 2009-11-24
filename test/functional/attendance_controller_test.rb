require File.dirname(__FILE__) + '/../test_helper'
require 'attendance_controller'

# Re-raise errors caught by the controller.
class AttendanceController; def rescue_action(e) raise e end; end

class AttendanceControllerTest < Test::Unit::TestCase
  
  fixtures :all

  def setup
    @controller = AttendanceController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    login_as :fester

    @user = User.find_by_login "fester"
    @contract = @user.facilitated_contracts.find(:first)

    @meeting = Meeting.new(:meeting_date => Date.new(2006,9,30))
    @contract.meetings << @meeting
    @meeting.create_participants
  end
  
  def test_delete_roll
    assert_equal 1, @contract.meetings.count
    xhr :put, :delete_roll, {:id => @meeting.id}

    assert_redirected_to :controller => 'contract', :action => 'attendance'
    
    @contract.reload
    assert_equal 0, @contract.meetings.count
  end
  
  def test_pick_roll
    xhr :put, :pick_roll, {:id => @contract.id}
    assert_template '/attendance/calendar_form'
  end
  
  def test_show_calendar
    xhr :put, :pick_roll, {:id => @contract.id}
    assert_template '/attendance/calendar_form'
  end
  
  def test_update
    participant = @meeting.meeting_participants.first
    assert_equal MeetingParticipant::OPTIONAL, participant.participation
    
    xhr :put, :update, {:id => participant.id, :participation => MeetingParticipant::TARDY.to_s}
    
    participant.reload
    assert_equal MeetingParticipant::TARDY, participant.participation
  end
  
  def test_update_all
    participant = @meeting.meeting_participants.first
    assert_equal MeetingParticipant::OPTIONAL, participant.participation

    xhr :put, :update_all, {:id => @meeting.id, :participation => MeetingParticipant::TARDY.to_s}
    
    participant.reload
    assert_equal MeetingParticipant::TARDY, participant.participation
  end
  
end
