require File.dirname(__FILE__) + '/../test_helper'
require 'node_groups_controller'

# Re-raise errors caught by the controller.
class NodeGroupsController; def rescue_action(e) raise e end; end

class NodeGroupsControllerTest < Test::Unit::TestCase
  fixtures :node_groups

  def setup
    @controller = NodeGroupsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:node_groups)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_node_group
    old_count = NodeGroup.count
    post :create, :node_group => { }
    assert_equal old_count+1, NodeGroup.count

    assert_redirected_to node_group_path(assigns(:node_group))
  end

  def test_should_show_node_group
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end

  def test_should_update_node_group
    put :update, :id => 1, :node_group => { }
    assert_redirected_to node_group_path(assigns(:node_group))
  end

  def test_should_destroy_node_group
    old_count = NodeGroup.count
    delete :destroy, :id => 1
    assert_equal old_count-1, NodeGroup.count

    assert_redirected_to node_group_path
  end
end
