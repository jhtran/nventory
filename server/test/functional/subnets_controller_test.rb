require File.dirname(__FILE__) + '/../test_helper'
require 'subnets_controller'

# Re-raise errors caught by the controller.
class SubnetsController; def rescue_action(e) raise e end; end

class SubnetsControllerTest < Test::Unit::TestCase

  def setup
    @controller = SubnetsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:subnets)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_subnet
    old_count = Subnet.count
    post :create, :subnet => { }
    assert_equal old_count+1, Subnet.count

    assert_redirected_to subnet_path(assigns(:subnet))
  end

  def test_should_show_subnet
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end

  def test_should_update_subnet
    put :update, :id => 1, :subnet => { }
    assert_redirected_to subnet_path(assigns(:subnet))
  end

  def test_should_destroy_subnet
    old_count = Subnet.count
    delete :destroy, :id => 1
    assert_equal old_count-1, Subnet.count

    assert_redirected_to subnets_path
  end
end
