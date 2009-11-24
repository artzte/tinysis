require File.dirname(__FILE__) + '/../test_helper'
require 'admin_controller'

# Re-raise errors caught by the controller.
class AdminController; def rescue_action(e) raise e end; end

class AdminControllerTest < Test::Unit::TestCase
  fixtures :users, :settings
  def setup
    @controller = AdminController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end
  
  def test_requires_login
    post :index
    assert_redirected_to :controller => 'school', :action => 'login'
  end
  
  def test_allows_staff_access_to_index
    login_as :fester
    get :index
    assert_template 'admin/index'
  end
  
  def test_allows_student_access_to_index
    login_as :fester_frank
    get :index
    assert_template 'admin/index'
  end
  
  def test_requires_admin_for_student_login
    login_as :fester_frank
    get :accounts
    assert_redirected_to :controller => 'school'
    assert_match /unexpected error/, @request.session["flash"][:notice]
  end
  
  def test_requires_admin_for_staff_login
    login_as :fester
    get :accounts
    assert_redirected_to :controller => 'school'
    assert_match /unexpected error/, @request.session["flash"][:notice]
  end
  
  def test_account
    login_as :admin
    get :account
  end
  
  def test_enrollments
    login_as :admin
    get :enrollments
  end
  
  def test_credits
    login_as :admin
    get :enrollments
  end
  
end
