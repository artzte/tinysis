require File.dirname(__FILE__) + '/../test_helper'
require 'credit_controller'

# Re-raise errors caught by the controller.
class CreditController; def rescue_action(e) raise e end; end

class CreditControllerTest < Test::Unit::TestCase
  def setup
    @controller = CreditController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
