require File.dirname(__FILE__) + '/../test_helper'
require 'datacenters_controller'

# Re-raise errors caught by the controller.
class DatacentersController; def rescue_action(e) raise e end; end

class DatacentersControllerTest < Test::Unit::TestCase

  def setup
    @controller = DatacentersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:datacenters)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end
  
  def test_should_create_datacenter
    old_count = Datacenter.count
    post :create, :datacenter => { }
    assert_equal old_count+1, Datacenter.count
    
    assert_redirected_to datacenter_path(assigns(:datacenter))
  end

  def test_should_show_datacenter
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end
  
  def test_should_update_datacenter
    put :update, :id => 1, :datacenter => { }
    assert_redirected_to datacenter_path(assigns(:datacenter))
  end
  
  def test_should_destroy_datacenter
    old_count = Datacenter.count
    delete :destroy, :id => 1
    assert_equal old_count-1, Datacenter.count
    
    assert_redirected_to datacenters_path
  end
end
