require File.dirname(__FILE__) + '/../test_helper'
require 'accounts_controller'

# Re-raise errors caught by the controller.
class AccountsController; def rescue_action(e) raise e end; end

class AccountsControllerTest < ActionController::TestCase

  def test_get_index
    assert_get_index
  end

  def test_get_new
    assert_get_new
  end
  
  def test_post_create
    assert_post_create(:account,{:account => {:login => 'foo1', :name => 'Foo 1 Bar', :email_address => 'foo1@bar.com', :password_hash => '*'}})
  end

  def test_post_create_xml
    assert_post_create(:account,{:account => {:login => 'foo2', :name => 'Foo 2 Bar', :email_address => 'foo2@bar.com', :password_hash => '*'}}, 'xml')
  end

  def test_get_show
    assert_get_show(:account)
  end

  def test_get_edit
    assert_get_edit(:account)
  end

  def test_put_update
    assert_put_update(:account,{:id => accounts(:jsmith).id, :account => { :name => 'foonewbar' } })
  end

  def test_put_update_xml
    assert_put_update(:account,{:id => accounts(:jsmith).id, :account => { :name => 'foonewbar' } }, 'xml')
  end
  
  def test_delete_destroy
    assert_delete_destroy(:account,accounts(:jsmith))
  end

  def test_delete_destroy_xml
    assert_delete_destroy(:account,accounts(:jsmith), 'xml')
  end
end
