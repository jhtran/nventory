require File.dirname(__FILE__) + '/../test_helper'
require 'racks_controller'

# Re-raise errors caught by the controller.
class RacksController; def rescue_action(e) raise e end; end

class RacksControllerTest < Test::Unit::TestCase
  fixtures :racks

  def setup
    @controller = RacksController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:racks)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end
  
  def test_should_create_rack
    old_count = Rack.count
    post :create, :rack => { }
    assert_equal old_count+1, Rack.count
    
    assert_redirected_to rack_path(assigns(:rack))
  end

  def test_should_show_rack
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end
  
  def test_should_update_rack
    put :update, :id => 1, :rack => { }
    assert_redirected_to rack_path(assigns(:rack))
  end
  
  def test_should_destroy_rack
    old_count = Rack.count
    delete :destroy, :id => 1
    assert_equal old_count-1, Rack.count
    
    assert_redirected_to racks_path
  end
end
