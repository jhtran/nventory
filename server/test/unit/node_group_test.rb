require File.dirname(__FILE__) + '/../test_helper'

class NodeGroupTest < Test::Unit::TestCase
  fixtures :node_groups

  # Test that the required fields are enforced
  def test_should_require_name
    ng = NodeGroup.create(:name => nil)
    assert ng.errors.on(:name)
  end

  # Verify that our fixture node group was created
  def test_fixture_node_group
    ng = NodeGroup.find(1)
    assert ng.valid?
  end

  # Now verify that we can't create a duplicate node group
  def test_no_duplicate_node_groups
    ng1 = NodeGroup.find(1)
    ng2 = NodeGroup.create(:name => ng1.name)
    assert ng2.errors.on(:name)
  end
end
