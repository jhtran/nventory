require File.dirname(__FILE__) + '/../test_helper'
require 'database_instance_relationships_controller'

# Re-raise errors caught by the controller.
class DatabaseInstanceRelationshipsController; def rescue_action(e) raise e end; end

class DatabaseInstanceRelationshipsControllerTest < Test::Unit::TestCase
  fixtures :database_instance_relationships

  def setup
    @controller = DatabaseInstanceRelationshipsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:database_instance_relationships)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end
  
  def test_should_create_database_instance_relationship
    old_count = DatabaseInstanceRelationship.count
    post :create, :database_instance_relationship => { }
    assert_equal old_count+1, DatabaseInstanceRelationship.count
    
    assert_redirected_to database_instance_relationship_path(assigns(:database_instance_relationship))
  end

  def test_should_show_database_instance_relationship
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end
  
  def test_should_update_database_instance_relationship
    put :update, :id => 1, :database_instance_relationship => { }
    assert_redirected_to database_instance_relationship_path(assigns(:database_instance_relationship))
  end
  
  def test_should_destroy_database_instance_relationship
    old_count = DatabaseInstanceRelationship.count
    delete :destroy, :id => 1
    assert_equal old_count-1, DatabaseInstanceRelationship.count
    
    assert_redirected_to database_instance_relationships_path
  end
end
