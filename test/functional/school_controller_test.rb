require File.dirname(__FILE__) + '/../test_helper'
require 'school_controller'
# Re-raise errors caught by the controller.
class SchoolController; def rescue_action(e) raise e end; end
class SchoolControllerTest < Test::Unit::TestCase

  def setup
    @controller = SchoolController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end
  # Replace this with your real tests.

  def test_truth
    assert true
  end
end
