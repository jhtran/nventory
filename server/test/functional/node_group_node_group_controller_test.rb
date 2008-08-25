require File.dirname(__FILE__) + '/../test_helper'
require 'node_group_node_group_assignments_controller'

# Re-raise errors caught by the controller.
class NodeGroupNodeGroupAssignmentsController; def rescue_action(e) raise e end; end

class NodeGroupNodeGroupAssignmentsControllerTest < Test::Unit::TestCase
  def setup
    @controller = NodeGroupNodeGroupAssignmentsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
