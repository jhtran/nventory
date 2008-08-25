require File.dirname(__FILE__) + '/../test_helper'
require 'ip_addresses_controller'

# Re-raise errors caught by the controller.
class IpAddressesController; def rescue_action(e) raise e end; end

class IpAddressesControllerTest < Test::Unit::TestCase
  def setup
    @controller = IpAddressesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
