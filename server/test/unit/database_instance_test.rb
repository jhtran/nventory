require File.dirname(__FILE__) + '/../test_helper'

class DatabaseInstanceTest < Test::Unit::TestCase
  fixtures :database_instances

  def test_database_instance_deletion_causes_node_database_instance_assignment_deletion
    node = Node.create(:name => 'bob-node-01', :status => Status.find(:first), :hardware_profile => HardwareProfile.find(:first))
    database_instance = DatabaseInstance.create(:name => 'db-01')
    node_database_instance_assignment = NodeDatabaseInstanceAssignment.create(:node => node, :database_instance => database_instance)
    
    assert_equal(0, node.errors.count, node.errors.to_yaml)
    assert_equal(0, database_instance.errors.count)
    assert_equal(0, node_database_instance_assignment.errors.count)
    assert_equal(1, node.node_database_instance_assignments.count) 
    assert_equal(1, node.database_instances.count) 
    
    node_database_instance_assignment_id = node_database_instance_assignment.id
    node_id = node.id
    database_instance_id = database_instance.id
    database_instance.destroy
    assert(Node.exists?(node_id))
    assert(!DatabaseInstance.exists?(database_instance_id))
    assert(!NodeDatabaseInstanceAssignment.exists?(node_database_instance_assignment_id))
  end
  
end
