require File.dirname(__FILE__) + '/../test_helper'
require 'operating_systems_controller'

# Re-raise errors caught by the controller.
class OperatingSystemsController; def rescue_action(e) raise e end; end

class OperatingSystemsControllerTest < Test::Unit::TestCase
  fixtures :operating_systems

  def setup
    @controller = OperatingSystemsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:operating_systems)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end
  
  def test_should_create_operating_system
    old_count = OperatingSystem.count
    post :create, :operating_system => { }
    assert_equal old_count+1, OperatingSystem.count
    
    assert_redirected_to operating_system_path(assigns(:operating_system))
  end

  def test_should_show_operating_system
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end
  
  def test_should_update_operating_system
    put :update, :id => 1, :operating_system => { }
    assert_redirected_to operating_system_path(assigns(:operating_system))
  end
  
  def test_should_destroy_operating_system
    old_count = OperatingSystem.count
    delete :destroy, :id => 1
    assert_equal old_count-1, OperatingSystem.count
    
    assert_redirected_to operating_systems_path
  end
end
