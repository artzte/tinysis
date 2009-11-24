require File.dirname(__FILE__) + '/../test_helper'
require 'contract_controller'

# Re-raise errors caught by the controller.
class ContractController; def rescue_action(e) raise e end; end

class ContractControllerTest < Test::Unit::TestCase
  
  fixtures :all
  
  def setup
    @controller = ContractController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @caleb = User.find_by_login 'myer'
    @contract = @caleb.facilitated_contracts.first
    
    login_as :myer
  end

	def test_index
    xhr :get, :index
    
    assert_template 'contract/index'
	  assert_select "p", /.*Found 5 contracts.*/
	end
	
	def test_enrollments
    xhr :get, :enrollments, :id => @contract.id
    
    assert_template 'contract/enrollments'
	end
	
	def test_summary
    xhr :get, :summary, :id => @contract.id
    
    assert_template 'contract/summary'
	end
	
	def test_setup
	end
	
	def test_attendance
    xhr :get, :attendance, :id => @contract.id
    
    assert_template 'contract/attendance'
	end
	
	def test_roll
	end
	def test_assignments
    xhr :get, :assignments, :id => @contract.id
    
    assert_template 'contract/assignments'
	end
  def test_turnins
	end
  def test_competencies
	end
	def test_add
	end
	def test_delete
	end
	def test_add_timeslot
	end
	def test_open_timeslot_form
	end
	def test_open_timeslot_link
	end
	def test_show_ealr_category
	end
	def test_update_ealr
	end
	def test_copy
	end

end
