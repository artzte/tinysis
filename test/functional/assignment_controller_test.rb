require File.dirname(__FILE__) + '/../test_helper'
require 'assignment_controller'

# Re-raise errors caught by the controller.
class AssignmentController; def rescue_action(e) raise e end; end

class AssignmentControllerTest < Test::Unit::TestCase

  fixtures :all
  
  def setup
    @controller = AssignmentController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    login_as :fester
    
    @user = User.find_by_login "fester"
    @contract = @user.facilitated_contracts.find(:first)
    @assignment = Assignment.new(:name => "Test", :due_date => Date.new(2006,1,1))
    @contract.assignments << @assignment

  end

  # get an add form
  def test_show_add
    xhr :get, :show_add, :contract_id => @contract.id
    
    assert_template 'assignment/_assignment_form'
  end
  
  # add an assignment
  def test_add
    xhr :put, :add, {:contract_id => @contract.id, :assignment=>{:name => "Here's my test", :due_date => "2005-1-1"}}
    
    @contract.reload
    
    assert_equal 2, @contract.assignments.count
    assert_template 'assignment/_assignments_table'
  end
  
  def test_show_edit
    xhr :get, :show_edit, {:id => @assignment.id}
    assert_template 'assignment/_assignment_form'
  end


  def test_save
    xhr :put, :save, {:id => @assignment.id, :assignment => {:name => "My new name"}}
    @assignment.reload
    assert_match /new name/, @assignment.name
    assert_template 'assignment/_assignments_table'
  end
  
  def test_destroy
    assert_equal 1, @contract.assignments.count
    xhr :put, :destroy, {:id => @assignment.id}
    @contract.reload
    assert_equal 0, @contract.assignments.count
    assert_template 'assignment/_assignments_table'
  end
    
  
  def test_expand_all
    xhr :put, :expand_all, {:id => @contract.id}
    assert_template 'assignment/_assignments_table'
  end
  
  def test_expand
    xhr :put, :expand, {:id => @assignment.id}
    assert_template 'assignment/_description'
  end
  
  
end
