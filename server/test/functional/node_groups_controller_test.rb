require File.dirname(__FILE__) + '/../test_helper'
require 'node_groups_controller'

# Re-raise errors caught by the controller.
class NodeGroupsController; def rescue_action(e) raise e end; end

class NodeGroupsControllerTest < ActionController::TestCase

  def test_get_index
    assert_get_index
  end

  def test_get_new
    assert_get_new
  end
  
  def test_post_create
    assert_post_create(:node_group,{:node_group => {:name => 'foo1'}})
  end

  def test_post_create_xml
    assert_post_create(:node_group,{:node_group => {:name => 'foo1'}}, 'xml')
  end

  def test_get_show
    assert_get_show(:node_group)
  end

  def test_get_edit
    assert_get_edit(:node_group)
  end

  def test_put_update
#    @update_data = {:id => node_groups(:web_servers).id, :node_group => {:name => 'foonewbar'}}
#    assert_put_update(:node_group, @update_data)
#    newnode = assigns(:node_group)
    @update_data = {:id => node_groups(:web_servers).id, :node_group_node_assignments => {:nodes => [nodes(:irvnventory1).id]}}
    assert_put_update(:node_group, @update_data)
    @update_data = {:id => node_groups(:web_servers).id, :node_group_node_assignments => {:nodes => [nodes(:irvnventory2).id]}}
    assert_put_update(:node_group, @update_data)
  end

  def test_put_update_xml
    assert_put_update(:node_group,{:id => node_groups(:web_servers).id,:node_group => {:name => 'foonewbar'}}, 'xml')
  end
  
  def test_delete_destroy
    assert_delete_destroy(:node_group,node_groups(:web_servers))
  end

  def test_delete_destroy_xml
    assert_delete_destroy(:node_group,node_groups(:web_servers), 'xml')
  end

end
