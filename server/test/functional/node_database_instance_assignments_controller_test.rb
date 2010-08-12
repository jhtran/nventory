require File.dirname(__FILE__) + '/../test_helper'
require 'node_database_instance_assignments_controller'

# Re-raise errors caught by the controller.
class NodeDatabaseInstanceAssignmentsController; def rescue_action(e) raise e end; end

class NodeDatabaseInstanceAssignmentsControllerTest < Test::Unit::TestCase

  def setup
    @controller = NodeDatabaseInstanceAssignmentsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:node_database_instance_assignments)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end
  
  def test_should_create_node_database_instance_assignment
    old_count = NodeDatabaseInstanceAssignment.count
    post :create, :node_database_instance_assignment => { }
    assert_equal old_count+1, NodeDatabaseInstanceAssignment.count
    
    assert_redirected_to node_database_instance_assignment_path(assigns(:node_database_instance_assignment))
  end

  def test_should_show_node_database_instance_assignment
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end
  
  def test_should_update_node_database_instance_assignment
    put :update, :id => 1, :node_database_instance_assignment => { }
    assert_redirected_to node_database_instance_assignment_path(assigns(:node_database_instance_assignment))
  end
  
  def test_should_destroy_node_database_instance_assignment
    old_count = NodeDatabaseInstanceAssignment.count
    delete :destroy, :id => 1
    assert_equal old_count-1, NodeDatabaseInstanceAssignment.count
    
    assert_redirected_to node_database_instance_assignments_path
  end
end
