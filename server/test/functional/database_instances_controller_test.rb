require File.dirname(__FILE__) + '/../test_helper'
require 'database_instances_controller'

# Re-raise errors caught by the controller.
class DatabaseInstancesController; def rescue_action(e) raise e end; end

class DatabaseInstancesControllerTest < Test::Unit::TestCase

  def setup
    @controller = DatabaseInstancesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:database_instances)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end
  
  def test_should_create_database_instance
    old_count = DatabaseInstance.count
    post :create, :database_instance => { }
    assert_equal old_count+1, DatabaseInstance.count
    
    assert_redirected_to database_instance_path(assigns(:database_instance))
  end

  def test_should_show_database_instance
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end
  
  def test_should_update_database_instance
    put :update, :id => 1, :database_instance => { }
    assert_redirected_to database_instance_path(assigns(:database_instance))
  end
  
  def test_should_destroy_database_instance
    old_count = DatabaseInstance.count
    delete :destroy, :id => 1
    assert_equal old_count-1, DatabaseInstance.count
    
    assert_redirected_to database_instances_path
  end
end
