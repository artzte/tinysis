require File.dirname(__FILE__) + '/../test_helper'
require 'status_controller'

# Re-raise errors caught by the controller.
class StatusController; def rescue_action(e) raise e end; end

class StatusControllerTest < Test::Unit::TestCase
  def setup
    @controller = StatusController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    login_as :hogg
    
    @hogg = User.find_by_login "hogg"
  end

	def test_index
    xhr :get, :index
    
    assert_template 'status/index'
	  assert_select "h1", /.*Elijah Hogg.*/
	  assert_select "p", /.*Found 5 contracts.*/
	  assert_select "p", /.*Found 5 students.*/
	end
	
	def test_index_myer
    xhr :get, :index, :t=>-1, :f=>"myer".to_hid, :g=>-1,:pg=>1
    
    assert_template 'status/index'
	  assert_select "p", /.*Found 5 contracts.*/
	  assert_select "p", /.*Found 5 students.*/
	  assert_select "td", /.*Myer Social_studies.*/
	  assert_select "td", /.*Myer Homeroom.*/
	  assert_select "td", /.*Myer Independent.*/
	  assert_select "td", /.*Myer Seminar.*/
	end

	def test_contract
    xhr :get, :contract
    
    assert_template 'status/contract'

	  assert_select "h1", /.*Elijah Hogg.*/
	  assert_select "p", /.*Found 5 contracts.*/
	  assert_select "td", /.*Hogg Math.*/
	  assert_select "td", /.*Hogg Science.*/
	  assert_select "td", /.*Hogg Homeroom.*/
	  assert_select "td", /.*Hogg Independent.*/
	  assert_select "td", /.*Hogg Seminar.*/
	end

	def test_coor
    xhr :get, :coor
    
    assert_template 'status/coor'

	  assert_select "h1", /.*COOR Status.*/
	  assert_select "p", /.*Found 3 coors.*/
	  assert_select "td", /.*Fester, Micah.*/
	  assert_select "td", /.*Hogg, Elijah.*/
	  assert_select "td", /.*Myer, Caleb.*/
	end
end
