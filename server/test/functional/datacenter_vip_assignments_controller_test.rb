require File.dirname(__FILE__) + '/../test_helper'
require 'datacenter_vip_assignments_controller'

# Re-raise errors caught by the controller.
class DatacenterVipAssignmentsController; def rescue_action(e) raise e end; end

class DatacenterVipAssignmentsControllerTest < Test::Unit::TestCase
  def setup
    @controller = DatacenterVipAssignmentsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
