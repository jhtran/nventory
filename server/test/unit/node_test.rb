require File.dirname(__FILE__) + '/../test_helper'

class NodeTest < Test::Unit::TestCase
  fixtures :nodes

  def test_node_deletion_causes_rack_node_assignment_deletion
    rack1 = Rack.create(:name => 'bob-rack-01')
    node1 = Node.create(:name => 'bob-node-01', :status => Status.find(:first), :hardware_profile => HardwareProfile.find(:first))
    rack1_node1_assignment = RackNodeAssignment.create(:rack => rack1, :node => node1)
    
    rack1_node1_assignment_id = rack1_node1_assignment.id
    node1_id = node1.id
    node1.destroy
    assert(!Node.exists?(node1_id))
    assert(!RackNodeAssignment.exists?(rack1_node1_assignment_id))
  end
  
  def test_node_deletion_causes_node_group_assignment_deletion
    node1 = Node.create(:name => 'bob-node-01', :status => Status.find(:first), :hardware_profile => HardwareProfile.find(:first))
    node1_node_group_assignment = NodeGroupNodeAssignment.create(:node => node1, :node_group => NodeGroup.find(:first))
    
    assert_not_nil(node1)
    assert_not_nil(node1_node_group_assignment)
    assert_equal(1, node1.node_group_node_assignments.count) 
    assert_equal(1, node1.node_groups.count) 
    
    node1_node_group_assignment_id = node1_node_group_assignment.id
    node1_id = node1.id
    node1.destroy
    assert(!Node.exists?(node1_id))
    assert(!NodeGroupNodeAssignment.exists?(node1_node_group_assignment_id))
  end
  
  
  def test_cant_delete_with_database_instance_assignment
    node = Node.create(:name => 'bob-node-01', :status => Status.find(:first), :hardware_profile => HardwareProfile.find(:first))
    database_instance = DatabaseInstance.create(:name => 'db1')
    assignment = NodeDatabaseInstanceAssignment.create(:node => node, :database_instance => database_instance)
    
    assert_not_nil(node)
    assert_not_nil(database_instance)
    assert_not_nil(assignment)
    assert_equal(1, node.node_database_instance_assignments.count) 
    assert_equal(1, node.database_instances.count) 
    
    # Test that we can't destroy
    begin
      node.destroy
    rescue Exception => destroy_error
      assert_equal(destroy_error.message, 'A node can not be destroyed that has database instances assigned to it.')
    else
      flunk('Trouble. We deleted a node that had a database instance assigned to it.')
    end
    
    # Remove the assignment, and make sure bob was destroyed
    assignment_id = assignment.id
    database_instance_id = database_instance.id
    node_id = node.id
    assignment.destroy
    node.destroy
    assert(!Node.exists?(node_id))
    assert(DatabaseInstance.exists?(database_instance_id))
    assert(!NodeDatabaseInstanceAssignment.exists?(assignment_id))
  end
  
end
