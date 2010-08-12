require File.dirname(__FILE__) + '/../test_helper'
require 'node_group_node_assignments_controller'

# Re-raise errors caught by the controller.
class NodeGroupNodeAssignmentsController; def rescue_action(e) raise e end; end

class NodeGroupNodeAssignmentsControllerTest < ActionController::TestCase

  def test_get_index
    assert_get_index
  end

  def test_get_new
    assert_get_new(true)
  end

  def test_post_create
    @create_data = { :node_group_node_assignment => { :node_group_id => node_groups(:db).id , :node_id => nodes(:irvnventory1).id } }
    assert_post_create(:node_group_node_assignment,@create_data)
    newngna = assigns(:node_group_node_assignment)
    assert_equal 'irvnventory1',newngna.node.name
    assert_equal 'db',newngna.node_group.name
  end

  def test_post_create_xml
    @create_data = { :node_group_node_assignment => { :node_group_id => node_groups(:db).id , :node_id => nodes(:irvnventory1).id } }
    assert_post_create(:node_group_node_assignment,@create_data, 'xml')
  end

  def test_get_show
    assert_get_show(:node_group_node_assignment)
  end

  def test_get_edit
    assert_get_edit(:node_group_node_assignment,true)
  end

  def test_put_update
    # sanity check prior to changing
    assert_equal 'nventory_80_pool',node_group_node_assignments(:nventory_80_pool_irvnventory1).node_group.name
    assert_equal 'irvnventory1',node_group_node_assignments(:nventory_80_pool_irvnventory1).node.name
    @update_data = { :id => node_group_node_assignments(:nventory_80_pool_irvnventory1).id, :node_group_node_assignment => { :node_id => nodes(:vmhost1).id } }
    assert_put_update(:node_group_node_assignment, @update_data)
    updatedngna = assigns(:node_group_node_assignment).reload
    assert_equal 'vmhost1',updatedngna.node.name
    assert_equal 'nventory_80_pool',updatedngna.node_group.name
  end

  def test_put_update_xml
    @update_data = { :id => node_group_node_assignments(:nventory_80_pool_irvnventory1).id, :node_group_node_assignment => { :node_id => nodes(:vmhost1).id } }
    assert_put_update(:node_group_node_assignment,@update_data, 'xml')
  end

  def test_delete_destroy
    assert_delete_destroy(:node_group_node_assignment,node_group_node_assignments(:nventory_80_pool_irvnventory1))
  end

  def test_delete_destroy_xml
    assert_delete_destroy(:node_group_node_assignment,node_group_node_assignments(:nventory_80_pool_irvnventory1), 'xml')
  end

end
