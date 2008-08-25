require File.dirname(__FILE__) + '/../test_helper'
require 'datacenter_rack_assignments_controller'

# Re-raise errors caught by the controller.
class DatacenterRackAssignmentsController; def rescue_action(e) raise e end; end

class DatacenterRackAssignmentsControllerTest < Test::Unit::TestCase
  fixtures :datacenter_rack_assignments

  def setup
    @controller = DatacenterRackAssignmentsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:datacenter_rack_assignments)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end
  
  def test_should_create_datacenter_rack_assignment
    old_count = DatacenterRackAssignment.count
    post :create, :datacenter_rack_assignment => { }
    assert_equal old_count+1, DatacenterRackAssignment.count
    
    assert_redirected_to datacenter_rack_assignment_path(assigns(:datacenter_rack_assignment))
  end

  def test_should_show_datacenter_rack_assignment
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end
  
  def test_should_update_datacenter_rack_assignment
    put :update, :id => 1, :datacenter_rack_assignment => { }
    assert_redirected_to datacenter_rack_assignment_path(assigns(:datacenter_rack_assignment))
  end
  
  def test_should_destroy_datacenter_rack_assignment
    old_count = DatacenterRackAssignment.count
    delete :destroy, :id => 1
    assert_equal old_count-1, DatacenterRackAssignment.count
    
    assert_redirected_to datacenter_rack_assignments_path
  end
end
