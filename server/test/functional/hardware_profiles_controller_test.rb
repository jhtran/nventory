require File.dirname(__FILE__) + '/../test_helper'
require 'hardware_profiles_controller'

# Re-raise errors caught by the controller.
class HardwareProfilesController; def rescue_action(e) raise e end; end

class HardwareProfilesControllerTest < Test::Unit::TestCase

  def setup
    @controller = HardwareProfilesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:hardware_profiles)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end
  
  def test_should_create_hardware_profile
    old_count = HardwareProfile.count
    post :create, :hardware_profile => { }
    assert_equal old_count+1, HardwareProfile.count
    
    assert_redirected_to hardware_profile_path(assigns(:hardware_profile))
  end

  def test_should_show_hardware_profile
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end
  
  def test_should_update_hardware_profile
    put :update, :id => 1, :hardware_profile => { }
    assert_redirected_to hardware_profile_path(assigns(:hardware_profile))
  end
  
  def test_should_destroy_hardware_profile
    old_count = HardwareProfile.count
    delete :destroy, :id => 1
    assert_equal old_count-1, HardwareProfile.count
    
    assert_redirected_to hardware_profiles_path
  end
end
