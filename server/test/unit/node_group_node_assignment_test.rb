require File.dirname(__FILE__) + '/../test_helper'

class NodeGroupNodeAssignmentTest < Test::Unit::TestCase
  fixtures :nodes
  fixtures :node_groups
  fixtures :node_group_node_group_assignments
  # See comment below about why we're not using this fixture
  #fixtures :node_group_node_assignments
  
  def test_virtual_assignments
    # The fixtures define a tree of 5 node groups that are connected like:
    # Five->Four->Three->Two->One
    # Assign the node to Three and Five.  The NodeGroupNodeAssignment
    # model should add virtual assignments to One, Two and Four, verify
    # that those virtual assignments are created.
    # (We can't use the fixture to create these assignments, as the fixture
    # inserts directly into the database, bypassing Active Record and our
    # hooks that create the virtual assingments.)
    ngna1 = NodeGroupNodeAssignment.create(:node_group_id => 3, :node_id => 1)
    ngna2 = NodeGroupNodeAssignment.create(:node_group_id => 5, :node_id => 1)
    assert_equal(5, NodeGroupNodeAssignment.count(:conditions => "node_id = 1"))
    NodeGroupNodeAssignment.find(:all, :conditions => "node_id = 1").each do |ngna|
      if ngna.node_group_id == 3 || ngna.node_group_id == 5
        assert !ngna.virtual_assignment?
      else
        assert ngna.virtual_assignment?
      end
    end
    
    # Now remove the assignment to Five, verify that the virtual assignment
    # to Four is removed and the assignments to One, Two and Three remain
    # intact.
    ngna2.destroy
    assert_equal(3, NodeGroupNodeAssignment.count(:conditions => "node_id = 1"))
    NodeGroupNodeAssignment.find(:all, :conditions => "node_id = 1").each do |ngna|
      if ngna.node_group_id == 3
        assert !ngna.virtual_assignment?
      else
        assert ngna.virtual_assignment?
      end
    end
  end
end
