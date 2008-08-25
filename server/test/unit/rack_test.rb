require File.dirname(__FILE__) + '/../test_helper'

class RackTest < Test::Unit::TestCase
  fixtures :racks
  
  def test_rack_deletion_causes_datacenter_rack_assignment_deletion
    bob = Datacenter.create(:name => 'Bob')
    rack1 = Rack.create(:name => 'bob-rack-01')
    bob_rack1_assignment = DatacenterRackAssignment.create(:datacenter => bob, :rack => rack1)
    
    bob_rack1_assignment_id = bob_rack1_assignment.id
    rack1_id = rack1.id
    rack1.destroy
    assert(!Rack.exists?(rack1_id))
    assert(!DatacenterRackAssignment.exists?(bob_rack1_assignment_id))
  end
  
  def test_cant_delete_with_node_assignment
    rack1 = Rack.create(:name => 'bob-rack-01')
    node1 = Node.create(:name => 'bob-node-01', :status => Status.find(:first), :hardware_profile => HardwareProfile.find(:first))
    rack1_node1_assignment = RackNodeAssignment.create(:rack => rack1, :node => node1)
    
    assert_not_nil(rack1)
    assert_not_nil(node1)
    assert_not_nil(rack1_node1_assignment)
    assert_equal(1, rack1.rack_node_assignments.count) 
    assert_equal(1, rack1.nodes.count) 
    
    # Test that we can't destroy
    begin
      rack1.destroy
    rescue Exception => destroy_error
      assert_equal(destroy_error.message, 'A rack can not be destroyed that has nodes assigned to it.')
    else
      flunk('Trouble. We deleted a rack that had a node assigned to it.')
    end
    
    # Remove the assignment, and make sure bob was destroyed
    rack1_node1_assignment_id = rack1_node1_assignment.id
    node1_id = node1.id
    rack1_id = rack1.id
    rack1_node1_assignment.destroy
    rack1.destroy
    assert(!Rack.exists?(rack1_id))
    assert(Node.exists?(node1_id)) # the node lives!
    assert(!RackNodeAssignment.exists?(rack1_node1_assignment_id))
  end
  
end
