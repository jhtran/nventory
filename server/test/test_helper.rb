ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'

$controllers = %w(account_group_account_group_assignments account_groups account_group_self_group_assignments accounts audits comments database_instances datacenter_node_rack_assignments datacenters datacenter_vip_assignments drives hardware_profiles ip_addresses ip_address_network_port_assignments lb_pool_node_assignments lb_pools lb_profiles name_aliases network_interfaces network_ports node_database_instance_assignments node_group_node_assignments node_group_node_group_assignments node_groups node_group_vip_assignments node_rack_node_assignments node_racks nodes operating_systems outlets service_profiles services service_service_assignments statuses storage_controllers subnets tool_tips utilization_metric_names utilization_metrics_by_node_groups utilization_metrics utilization_metrics_global vip_lb_pool_assignments vips virtual_assignments volume_drive_assignments volume_node_assignments volumes tags taggings)

class ActiveSupport::TestCase
  # Transactional fixtures accelerate your tests by wrapping each test method
  # in a transaction that's rolled back on completion.  This ensures that the
  # test database remains unchanged so your fixtures don't have to be reloaded
  # between every test method.  Fewer database queries means faster tests.
  #
  # Read Mike Clark's excellent walkthrough at
  #   http://clarkware.com/cgi/blosxom/2005/10/24#Rails10FastTesting
  #
  # Every Active Record database supports transactions except MyISAM tables
  # in MySQL.  Turn off transactional fixtures in this case; however, if you
  # don't care one way or the other, switching from MyISAM to InnoDB tables
  # is recommended.
  #
  # The only drawback to using transactional fixtures is when you actually 
  # need to test transactions.  Since your test is bracketed by a transaction,
  # any transactions started in your code will be automatically rolled back.
  self.use_transactional_fixtures = true

  # Instantiated fixtures are slow, but give you @david where otherwise you
  # would need people(:david).  If you don't want to migrate your existing
  # test cases which use the @david style and don't mind the speed hit (each
  # instantiated fixtures translates to a database query per test method),
  # then set this back to true.
  self.use_instantiated_fixtures  = false

  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all
  # the following fixtures aren't real tables
  set_fixture_class :lb_pools => NodeGroup
  set_fixture_class :lb_pool_node_group_assignments => NodeGroupNodeAssignment
  set_fixture_class :volumes_served => Volume
  set_fixture_class :volumes_mounted => Volume

  # Add more helper methods to be used by all tests here...

  def assert_deny_authz(format=nil)
    assert_equal 'testuser',assigns(:user).login
    if format == 'xml'
      assert_response :success
      assert @response.body =~ /Permission Denied/
    else
      assert_response :redirect
      assert @response.flash[:error] =~ /Permission Denied/
      assert @response.redirected_to[:action] == :index
    end
  end

  def assert_logged_in
    assert assigns(:user)
  end

  def assert_get_index
    get :index
    assert_response :success
    assert_logged_in
    assert_equal 'text/html',@response.content_type
    assert assigns(:objects), "didn't return @objects"
    assert assigns(:objects).size > 0, "returns 0 @objects"

    get :index, :format => "xml"
    assert_response :success
    assert_equal 'application/xml',@response.content_type
    assert assigns(:objects)
  end

  def assert_get_new(custom_controller=false)
    get :new
    # custom controllers are join tables
    unless custom_controller
      assert_deny_authz
    end
    assert assigns(:object)
    if @response.success?
      assert assigns(assigns(:object).class.to_s.tableize.singularize.to_sym)
    end
  end

  def assert_get_show(ctrlr)
    model = ctrlr.to_s.camelize.constantize
    get :show, :id => model.first
    assert_response :success
    assert_logged_in
    assert_equal 'text/html',@response.content_type
    assert assigns(:object)
    assert assigns(ctrlr)
  end

  def assert_get_edit(ctrlr,custom_controller=false)
    model = ctrlr.to_s.camelize.constantize
    get :edit, :id => model.first
    assert_logged_in
    # custom controllers are join tables
    unless custom_controller
      assert_deny_authz
    end
    mysession = {'account_id' => accounts(:jsmith).id.to_s }
    accounts(:jsmith).authz.has_role 'admin'
    get :edit, {:id => model.first}, mysession
    assert_response :success
    assert assigns(ctrlr)
    assert_equal model.first.id,assigns(ctrlr).id
  end

  def assert_post_create(ctrlr,create_data,format=nil)
    model = ctrlr.to_s.camelize.constantize
    # testuser default session account doesn't have authoriz, should be denied 
    if @response.assigns.empty? && !session[:account_id]
      if format == 'xml'
        create_data[:format] = 'xml'
        post(:create, create_data)
        assert_deny_authz('xml')
      else
        post(:create, create_data)
        assert_deny_authz
      end
      # change the @auth object to authorized user and re-attempt to create succesfully
      mysession = {'account_id' => accounts(:jsmith).id.to_s }
      accounts(:jsmith).authz.has_role 'admin'
    end # if assigns(:user).login == 'testuser'

    assert_difference('model.count'){ format == 'xml' ? post(:create, create_data, mysession) : post(:create, create_data, mysession) }
    assert_match /was successfully created/,@response.flash[:notice]
    assert_redirected_to @controller.url_for(:id => assigns(ctrlr).id, :action => :show, :controller => ctrlr.to_s.pluralize ) unless format == 'xml'
    assert assigns(ctrlr)
  end

  def assert_put_update(ctrlr,update_data,format=nil)
    model = ctrlr.to_s.camelize.constantize
    # testuser default session account doesn't have authoriz, should be denied 
    if @response.assigns.empty? && !session[:account_id]
      update_data[:format] = 'xml' if format == 'xml'
      put(:update, update_data)
      format == 'xml' ?  assert_deny_authz('xml') : assert_deny_authz
      # change the @auth object and re-attempt to update
      accounts(:jsmith).authz.has_role 'admin'
    end

    put(:update, update_data, {:account_id => accounts(:jsmith).id.to_s})
    assert_match /was successfully updated/,@response.flash[:notice]
    assert_redirected_to @controller.url_for(:id => assigns(ctrlr).id, :action => :show, :controller => ctrlr.to_s.pluralize ) unless format == 'xml'
    assert assigns(ctrlr)
  end

  def assert_delete_destroy(ctrlr,obj,format=nil)
    model = ctrlr.to_s.camelize.constantize
    # testuser default session account doesn't have authoriz, should be denied 
    if format == 'xml'
      delete(:destroy, :id => obj.id, :format => 'xml')
      assert_deny_authz('xml')
    else
      delete(:destroy, :id => obj.id)
      assert_deny_authz
    end

    # change the @auth object and re-attempt to destroy
    accounts(:jsmith).authz.has_role 'admin'
    assert_difference('model.count', -1) do
      if format == 'xml' 
        delete(:destroy, {:id => obj.id}, {'account_id' => accounts(:jsmith).id.to_s,:format => 'xml'}) 
      else
        delete(:destroy, {:id => obj.id}, {'account_id' => accounts(:jsmith).id.to_s})
      end
    end
    assert_redirected_to @controller.url_for(:action => :index) unless format == 'xml'
    assert assigns(ctrlr)
  end

end
