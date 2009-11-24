require File.dirname(__FILE__) + '/../test_helper'
require 'enrollment_controller'

# Re-raise errors caught by the controller.
class EnrollmentController; def rescue_action(e) raise e end; end

class EnrollmentControllerTest < Test::Unit::TestCase
  def setup
    @controller = EnrollmentController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
