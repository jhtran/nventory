require 'test_helper'

class StatusTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_save_without_name
    status = Status.new
    assert !status.save
  end

  def test_save_duplicate_name
    status = Status.new({ :name => 'setup' })
    assert !status.save
  end

  def test_save
    status = Status.new({ :name => 'goodstatus' })
    assert status.save
  end

  def test_delete
    status = Status.new({ :name => 'goodstatus' })
    status.delete
    assert status.delete
  end
end
