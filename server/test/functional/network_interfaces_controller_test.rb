require File.dirname(__FILE__) + '/../test_helper'
require 'network_interfaces_controller'

# Re-raise errors caught by the controller.
class NetworkInterfacesController; def rescue_action(e) raise e end; end

class NetworkInterfacesControllerTest < Test::Unit::TestCase
  def setup
    @controller = NetworkInterfacesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
