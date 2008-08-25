require File.dirname(__FILE__) + '/../test_helper'
require 'vips_controller'

# Re-raise errors caught by the controller.
class VipsController; def rescue_action(e) raise e end; end

class VipsControllerTest < Test::Unit::TestCase
  fixtures :vips

  def setup
    @controller = VipController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
