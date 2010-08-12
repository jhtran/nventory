require File.dirname(__FILE__) + '/../test_helper'
require 'rack_node_assignments_controller'

# Re-raise errors caught by the controller.
class RackNodeAssignmentsController; def rescue_action(e) raise e end; end

class RackNodeAssignmentsControllerTest < Test::Unit::TestCase

  def setup
    @controller = RackNodeAssignmentsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:rack_node_assignments)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end
  
  def test_should_create_rack_node_assignment
    old_count = RackNodeAssignment.count
    post :create, :rack_node_assignment => { }
    assert_equal old_count+1, RackNodeAssignment.count
    
    assert_redirected_to rack_node_assignment_path(assigns(:rack_node_assignment))
  end

  def test_should_show_rack_node_assignment
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end
  
  def test_should_update_rack_node_assignment
    put :update, :id => 1, :rack_node_assignment => { }
    assert_redirected_to rack_node_assignment_path(assigns(:rack_node_assignment))
  end
  
  def test_should_destroy_rack_node_assignment
    old_count = RackNodeAssignment.count
    delete :destroy, :id => 1
    assert_equal old_count-1, RackNodeAssignment.count
    
    assert_redirected_to rack_node_assignments_path
  end
end
