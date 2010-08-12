require File.dirname(__FILE__) + '/../test_helper'
require 'outlets_controller'

# Re-raise errors caught by the controller.
class OutletsController; def rescue_action(e) raise e end; end

class OutletsControllerTest < Test::Unit::TestCase

  def setup
    @controller = OutletsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:outlets)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end
  
  def test_should_create_outlet
    old_count = Outlet.count
    post :create, :outlet => { }
    assert_equal old_count+1, Outlet.count
    
    assert_redirected_to outlet_path(assigns(:outlet))
  end

  def test_should_show_outlet
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end
  
  def test_should_update_outlet
    put :update, :id => 1, :outlet => { }
    assert_redirected_to outlet_path(assigns(:outlet))
  end
  
  def test_should_destroy_outlet
    old_count = Outlet.count
    delete :destroy, :id => 1
    assert_equal old_count-1, Outlet.count
    
    assert_redirected_to outlets_path
  end
end
