require File.dirname(__FILE__) + '/../test_helper'

class NodeGroupTest < Test::Unit::TestCase
  fixtures :nodes
  fixtures :node_groups
  fixtures :node_group_node_group_assignments
  fixtures :node_group_node_assignments
  
  # Test that the required fields are enforced
  def test_should_require_name
    ng = NodeGroup.create(:name => nil)
    assert ng.errors.on(:name)
  end
  
  # Verify that our fixture node group was created
  def test_fixture_node_group
    ng = node_groups(:one)
    assert ng.valid?
  end
  
  # Now verify that we can't create a duplicate node group
  def test_no_duplicate_node_groups
    ng1 = node_groups(:one)
    ng2 = NodeGroup.create(:name => ng1.name)
    assert ng2.errors.on(:name)
  end
  
  def test_parent_groups
    ng2 = node_groups(:two)
    ng1 = node_groups(:one)
    assert_equal [ng1], ng2.parent_groups
  end
  
  def test_child_groups
    ng2 = node_groups(:two)
    ng3 = node_groups(:three)
    assert_equal [ng3], ng2.child_groups
  end
  
  def test_nodes
    # Test the fixture assignment
    ng3 = node_groups(:three)
    node1 = nodes(:one)
    assert_equal [node1], ng3.nodes
    
    # We need to kill the fixture NGNAs and create ones here so the
    # AR callbacks get called and create the appropriate virtual assignments.
    ngna1 = node_group_node_assignments(:one)
    ngna1.destroy
    ngna1 = NodeGroupNodeAssignment.create(:node_group_id => 3, :node_id => 1)
    ngna2 = node_group_node_assignments(:two)
    ngna2.destroy
    ngna2 = NodeGroupNodeAssignment.create(:node_group_id => 5, :node_id => 1)
    # And toss in another assignment to flesh out the various situations
    ngna3 = NodeGroupNodeAssignment.create(:node_group_id => 3, :node_id => 2)
    ngna3 = node_group_node_assignments(:two)
    
    node1 = nodes(:one)
    node2 = nodes(:two)
    ng1 = node_groups(:one)
    assert_equal 2, ng1.nodes.length
    assert ng1.nodes.include?(node1)
    assert ng1.nodes.include?(node2)
    ng3 = node_groups(:three)
    assert_equal 2, ng3.nodes.length
    assert ng3.nodes.include?(node1)
    assert ng3.nodes.include?(node2)
    ng4 = node_groups(:four)
    assert_equal [node1], ng4.nodes
    ng5 = node_groups(:four)
    assert_equal [node1], ng5.nodes
  end
  
  def test_real_node_group_node_assignments
    ngna1 = node_group_node_assignments(:one)
    ngna1.destroy
    ngna1 = NodeGroupNodeAssignment.create(:node_group_id => 3, :node_id => 1)
    ngna2 = node_group_node_assignments(:two)
    ngna2.destroy
    ngna2 = NodeGroupNodeAssignment.create(:node_group_id => 5, :node_id => 1)
    
    ng1 = node_groups(:one)
    assert_equal [], ng1.real_node_group_node_assignments
    ng3 = node_groups(:three)
    assert_equal [ngna1], ng3.real_node_group_node_assignments
  end
  
  def test_real_nodes
    ngna1 = node_group_node_assignments(:one)
    ngna1.destroy
    ngna1 = NodeGroupNodeAssignment.create(:node_group_id => 3, :node_id => 1)
    ngna2 = node_group_node_assignments(:two)
    ngna2.destroy
    ngna2 = NodeGroupNodeAssignment.create(:node_group_id => 5, :node_id => 1)
    
    ng1 = node_groups(:one)
    assert_equal [], ng1.real_nodes
    ng3 = node_groups(:three)
    node1 = nodes(:one)
    assert_equal [node1], ng3.real_nodes
  end
  
  def test_virtual_node_group_node_assignments
    ngna1 = node_group_node_assignments(:one)
    ngna1.destroy
    ngna1 = NodeGroupNodeAssignment.create(:node_group_id => 3, :node_id => 1)
    ngna2 = node_group_node_assignments(:two)
    ngna2.destroy
    ngna2 = NodeGroupNodeAssignment.create(:node_group_id => 5, :node_id => 1)
    
    ng1 = node_groups(:one)
    assert_equal 2, ng1.virtual_node_group_node_assignments.length
    ng3 = node_groups(:three)
    assert_equal 1, ng3.virtual_node_group_node_assignments.length
    ng5 = node_groups(:five)
    assert_equal 0, ng5.virtual_node_group_node_assignments.length
  end
  
  def test_virtual_nodes
    ngna1 = node_group_node_assignments(:one)
    ngna1.destroy
    ngna1 = NodeGroupNodeAssignment.create(:node_group_id => 3, :node_id => 1)
    ngna2 = node_group_node_assignments(:two)
    ngna2.destroy
    ngna2 = NodeGroupNodeAssignment.create(:node_group_id => 5, :node_id => 1)
    
    node1 = nodes(:one)
    node2 = nodes(:two)
    ng1 = node_groups(:one)
    assert_equal 2, ng1.virtual_nodes.length
    assert ng1.virtual_nodes.include?(node1)
    assert ng1.virtual_nodes.include?(node2)
    ng3 = node_groups(:three)
    assert_equal [node2], ng3.virtual_nodes
    ng5 = node_groups(:five)
    assert_equal 0, ng5.virtual_nodes.length
  end
  
  def test_set_child_groups
    ng1 = node_groups(:one)
    ng1.set_child_groups([3,4])
    ng3 = node_groups(:three)
    ng4 = node_groups(:four)
    assert_equal 2, ng1.child_groups.length
    assert ng1.child_groups.include?(ng3)
    assert ng1.child_groups.include?(ng4)
  end
  
  def test_set_nodes
    ngna1 = node_group_node_assignments(:one)
    ngna1.destroy
    ngna1 = NodeGroupNodeAssignment.create(:node_group_id => 3, :node_id => 1)
    ngna2 = node_group_node_assignments(:two)
    ngna2.destroy
    ngna2 = NodeGroupNodeAssignment.create(:node_group_id => 5, :node_id => 1)
    
    # ng3 will have one real and one virtual assignment.  Run a test such
    # that the virtual assignment must be converted to a real assignment and 
    # the existing real assignment left alone.
    ng3 = node_groups(:three)
    ng3.set_nodes([1,2])
    assert_equal 2, ng3.nodes.length
    node1 = nodes(:one)
    node2 = nodes(:two)
    assert ng3.nodes.include?(node1)
    assert ng3.nodes.include?(node2)
    assert_equal 2, ng3.real_nodes.length
    assert_equal [], ng3.virtual_nodes
    
    # ng5 will just have one real assignment.  Run a test such that the
    # existing assignment must be removed and a new one created.
    ng5 = node_groups(:five)
    ng5.set_nodes([2])
    node2 = nodes(:two)
    assert_equal [node2], ng5.nodes
    assert_equal [node2], ng5.real_nodes
    assert_equal [], ng5.virtual_nodes
  end
  
  def test_all_parent_groups
    ng1 = node_groups(:one)
    ng2 = node_groups(:two)
    ng3 = node_groups(:three)
    ng4 = node_groups(:four)
    ng5 = node_groups(:five)
    assert_equal 4, ng5.all_parent_groups
    assert ng5.all_parent_groups.include?(ng1)
    assert ng5.all_parent_groups.include?(ng2)
    assert ng5.all_parent_groups.include?(ng3)
    assert ng5.all_parent_groups.include?(ng4)
  end
  
  def test_all_child_groups
    ng1 = node_groups(:one)
    ng2 = node_groups(:two)
    ng3 = node_groups(:three)
    ng4 = node_groups(:four)
    ng5 = node_groups(:five)
    assert_equal 4, ng1.all_child_groups
    assert ng5.all_child_groups.include?(ng2)
    assert ng5.all_child_groups.include?(ng3)
    assert ng5.all_child_groups.include?(ng4)
    assert ng5.all_child_groups.include?(ng5)
  end
  
  def test_all_child_groups_except_ngnga
    ng3 = node_groups(:three)
    ng4 = node_groups(:four)
    # Assignment from group three to group four
    ngnga1 = node_group_node_group_assignment(:three)
    # Assignment from group four to group five
    ngnga1 = node_group_node_group_assignment(:four)
    assert_equal 0, ng3.all_child_groups_except_ngnga(ngnga1)
    assert_equal 1, ng3.all_child_groups_except_ngnga(ngnga2)
    assert_equal [ng4], ng3.all_child_groups_except_ngnga(ngnga2)
  end
  
  def test_all_child_nodes_except_ngna
    ngna1 = node_group_node_assignments(:one)
    ngna1.destroy
    ngna1 = NodeGroupNodeAssignment.create(:node_group_id => 3, :node_id => 1)
    ngna2 = node_group_node_assignments(:two)
    ngna2.destroy
    ngna2 = NodeGroupNodeAssignment.create(:node_group_id => 5, :node_id => 1)
    ngna3 = NodeGroupNodeAssignment.create(:node_group_id => 3, :node_id => 2)
    ngna3 = node_group_node_assignments(:two)
    
    node1 = nodes(:one)
    node2 = nodes(:two)
    
    # If we ignore ngna1 then group three should still have both nodes as
    # children since group three inherits node 1 via the assignment to group 5
    ng3 = node_groups(:three)
    assert_equal 2, ng3.all_child_nodes_except_ngna(ngna1).length
    assert ng3.all_child_nodes_except_ngna(ngna1).include?(node1)
    assert ng3.all_child_nodes_except_ngna(ngna1).include?(node2)
    # If we ignore ngna2 then group four should not have any children
    ng4 = node_groups(:four)
    assert_equal [], ng4.all_child_nodes_except_ngna(ngna2)
    # If we ignore ngna3 then group three should only have node 1 as a child
    assert_equal [node1], ng3.all_child_nodes_except_ngna(ngna3)
  end
  
  def test_all_child_nodes_except_ngnga
    ngna1 = node_group_node_assignments(:one)
    ngna1.destroy
    ngna1 = NodeGroupNodeAssignment.create(:node_group_id => 3, :node_id => 1)
    ngna2 = node_group_node_assignments(:two)
    ngna2.destroy
    ngna2 = NodeGroupNodeAssignment.create(:node_group_id => 5, :node_id => 1)
    ngna3 = NodeGroupNodeAssignment.create(:node_group_id => 3, :node_id => 2)
    ngna3 = node_group_node_assignments(:two)
    
    node1 = nodes(:one)
    node2 = nodes(:two)
    ngnga3 = node_group_node_group_assignments(:three)
    ngnga4 = node_group_node_group_assignments(:four)
    
    # If we ignore ngnga3 then group two should have no children
    ng2 = node_groups(:two)
    assert_equal [], ng2.all_child_nodes_except_ngnga(ngnga3)
    # If we ignore ngnga4 then group two should still have both nodes as
    # children
    assert_equal 2, ng2.all_child_nodes_except_ngnga(ngna4).length
    assert ng2.all_child_nodes_except_ngnga(ngnga4).include?(node1)
    assert ng2.all_child_nodes_except_ngnga(ngnga4).include?(node2)
    # As should group three
    ng3 = node_groups(:three)
    assert_equal 2, ng3.all_child_nodes_except_ngnga(ngna4).length
    assert ng3.all_child_nodes_except_ngnga(ngnga4).include?(node1)
    assert ng3.all_child_nodes_except_ngnga(ngnga4).include?(node2)
  end
end
