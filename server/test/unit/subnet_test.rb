require File.dirname(__FILE__) + '/../test_helper'

class SubnetTest < Test::Unit::TestCase
  fixtures :subnets

  # Test that the required fields are enforced
  def test_should_require_network
    s = Subnet.create(:network => nil)
    assert s.errors.on(:network)
  end
  def test_should_require_netmask
    s = Subnet.create(:netmask => nil)
    assert s.errors.on(:netmask)
  end
  def test_should_require_broadcast
    s = Subnet.create(:broadcast => nil)
    assert s.errors.on(:broadcast)
  end

  # Verify that our fixture subnet was created
  def test_fixture_subnet
    s = Subnet.find(1)
    assert s.valid?
  end

  # Now verify that we can't create a duplicate subnet
  def test_no_duplicate_subnets
    s1 = Subnet.find(1)
    s2 = Subnet.create(:network => s1.network)
    assert s2.errors.on(:network)
  end
end
