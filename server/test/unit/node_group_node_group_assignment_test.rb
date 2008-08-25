require File.dirname(__FILE__) + '/../test_helper'

class NodeGroupNodeGroupAssignmentTest < Test::Unit::TestCase
  fixtures :node_group_node_group_assignments

  # Test that the required fields are enforced
  def test_should_require_parent
    ngnga = NodeGroupNodeGroupAssignment.create(:parent_id => nil)
    assert ngnga.errors.on(:parent_id)
  end
  def test_should_require_child
    ngnga = NodeGroupNodeGroupAssignment.create(:child_id => nil)
    assert ngnga.errors.on(:child_id)
  end

  # Verify that our fixture node group connection was created
  def test_fixture_node_group_node_group_assignment
    ngnga = NodeGroupNodeGroupAssignment.find(1)
    assert ngnga.valid?
  end

  # Now verify that we can't create a cycle in our connections
  def test_no_cycles_in_node_group_node_group_assignments
    ngnga_parent = NodeGroupNodeGroupAssignment.find(1)
    ngnga_child = ngnga_parent#children.first
    ngnga_cycle = NodeGroupNodeGroupAssignment.create(:parent_id => ngnga_child,
                                           :child_id => ngnga_parent)
    assert ngnga_cycle.errors.on(:child_id)
  end
end
