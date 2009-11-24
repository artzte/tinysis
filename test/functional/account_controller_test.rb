require File.dirname(__FILE__) + '/../test_helper'
require 'account_controller'

# Re-raise errors caught by the controller.
class AccountController; def rescue_action(e) raise e end; end

class AccountControllerTest < Test::Unit::TestCase
  
  fixtures :users, :settings
  
  def setup
    @controller = AccountController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    setup_emailer
  end

  # Replace this with your real tests.
  def test_log_out
    login_as :admin
    
    get :log_out
    
    assert_redirected_to :controller => "school"
    assert_nil session[:user_id]

    assert_match /been logged out/, @request.session["flash"][:notice]

  end
  
  def test_log_in
    post :log_in, {:user => {:login=>'admin',:pass=>'testme'}}
    assert_redirected_to :controller => "status"
    assert_equal 'admin'.hash, @request.session[:user_id]
  end
  
  def test_log_in_refuses_bad_password
    post :log_in, {:user => {:login=>'admin',:pass=>'incorrect'}}
    assert_redirected_to :controller => "school", :action => 'login'
  end
  
  def test_reset_sends_reset_email
    post :reset, {:user => {:email=>'admin@you.com'}}
    assert_template 'account/_reset_confirmation'
    assert_equal 1, ActionMailer::Base.deliveries.length
  end
  
  def test_reset_does_not_find_email
    post :reset, {:user => {:email=>'smelly@finger.com'}}
    assert_template 'account/_reset_notfound'
    assert_equal 0, ActionMailer::Base.deliveries.length
  end
  
  
end
