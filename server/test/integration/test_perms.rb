require File.dirname(__FILE__) + '/../test_helper'

class AuthPermTest < ActionController::IntegrationTest 
  def custom_controller?(ctrlr)
    # custom_controller, as defined in applications_controller is generally join tables
    return true if ctrlr =~ /_assignments/
    return true if ctrlr == 'name_aliases'  
    return true if ctrlr == 'volumes'  
    return true if ctrlr == 'taggings'
    return false
  end

  #  Note that rails test environment auto sets SSO user 'testuser'
  def test_nonprivileged
    $loginuser = nil
    get "/"
    assert_response :success
    assert_template 'dashboard/index.html.erb'
  # FIXME - should search elements to ensure that none of the left nav links have the 'N' shortcut link to create new obj
    # CREATE ensure main obj controllers (non-join model) deny non-priv user
    $controllers.each do |ctrlr|
      print "***** CONTROLLER: #{ctrlr}\n"
      next if custom_controller?(ctrlr)
      # next if are custom auth controllers
      get url_for(:controller => ctrlr, :action => :new)
      assert_redirected_to url_for(:controller => ctrlr, :action => :index), "#{ctrlr} new allowed but not supposed to"
      assert_equal "Permission Denied.  You do not have the proper authorization",flash[:error]
    end # $controllers.each do 

    # DESTROY - ensure all controllers deny non-priv user by not executing the destroy
    $controllers.each do |ctrlr|
      model = ctrlr.camelize.singularize.constantize
      record = model.first
      priorsize = model.count
      unless record
        puts "***** #{ctrlr}: NO FIXTURE EXISTS *****"
        next
      end
      delete url_for(:controller => ctrlr, :id => record.id)
      assert_equal priorsize,model.count
    end # $controllers.each do 

    # ADDAUTH - ensure all controllers deny non-priv user by not executing the addauth
    $controllers.each do |ctrlr|
      next if custom_controller?(ctrlr)
      model = ctrlr.camelize.singularize.constantize
      record = model.first
      next unless record
      post ctrlr, {}
      assert_redirected_to url_for(:controller => ctrlr, :action => :index), "#{ctrlr} should've redirected to index with permission denied"
      assert_equal 'Permission Denied.  You do not have the proper authorization',flash[:error]
    end # $controllers.each do 
  end

  def test_global_admin
    $loginuser = 'jsmith'
    user = Account.find_by_login($loginuser)
    get '/'
    assert_select "#account_links", /Welcome back,.*John Smith/
    assert_select "#account_links", /Logout \(SSO\)/
    # each controller view, the bottom 'Permission' link should show up to show perms
#%w(virtual_assignments).each do |ctrlr|
    $controllers.each do |ctrlr|
      next if ctrlr == 'lb_pool_node_assignments' # no view for this one
      next if ctrlr == 'utilization_metrics_global' # no view for this one
      print "***** CONTROLLER: #{ctrlr}\n"
      get "/#{ctrlr}"
      # the side nav each obj should allow the 'N' to create new obj
      assert_select('ul'){|ul| assert_select 'li', /N&nbsp;&nbsp;/ }
      assert_select "#perms", 'Permissions'
      xhr :post, "#{ctrlr}/get_perms"
      rows = assert_select("tr")
      assert_equal 3,rows.size
      rows.delete(rows[0]) # delete header row
      assert_select rows[0],'td','updater'
      assert_select rows[0],'td','jdoe'
      assert_select rows[0],'td','All'
      assert_select rows[0],'td','Global'
      assert_select rows[1],'td','admin'
      assert_select rows[1],'td','jsmith'
      assert_select rows[1],'td','All'
      assert_select rows[1],'td','Global'
      xhr :post, "#{ctrlr}/addauth", {ctrlr => {:useraccs => [account_groups(:jblow_self).id], :role => 'updater',:groupaccs => [''], :attrs => ['']}}
      xhr :post, "#{ctrlr}/addauth", {ctrlr => {:useraccs => [account_groups(:jblow_self).id], :role => 'destroyer',:groupaccs => [''], :attrs => ['']}}
      xhr :post, "#{ctrlr}/get_perms"
      rows = assert_select("tr")
      assert_equal 5,rows.size
    end # $controllers.each do |ctrlr|
  end # def test_global_admin

end
