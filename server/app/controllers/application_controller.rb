# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  # GET requests with no user agent are probably monitoring agents of some
  # sort (including load balancer health checks) and creating sessions for
  # them just fills up the session table with junk
  ###  PS-364 rails 2.3 migration - DEPRECATION WARNING: Disabling sessions for a single controller has been deprecated. Sessions are now lazy loaded. So if you don't access them, consider them off ###
  # session :off, :if => Proc.new { |request| request.env['HTTP_USER_AGENT'].blank? && request.get? }

  # Turn on the exception_notification plugin
  # See environment.rb for the email address(s) to which exceptions are mailed
  include ExceptionNotifiable

  # Turn on the ssl_requirement plugin
  # The login controller uses it to ensure that authentication occurs
  # over SSL.  All other activity that comes in on the SSL side (https)
  # will be redirected to the non-SSL (http) side.
  include SslRequirement

  # Turn on the acts_as_audited plugin for appropriate models
  audit Account, DatabaseInstance, DatabaseInstanceRelationship,
    Datacenter, DatacenterNodeRackAssignment, LbPoolNodeAssignment,
    DatacenterVipAssignment, HardwareProfile, UtilizationMetricName,
    IpAddress, NetworkInterface, Node, NodeDatabaseInstanceAssignment,
    NodeGroup, NodeGroupNodeAssignment, LbPool, LbProfile, Service,
    VipLbPoolAssignment, NodeGroupNodeGroupAssignment, OperatingSystem, Outlet, NodeRack,
    NodeRackNodeAssignment, Status, Subnet, Vip, ServiceServiceAssignment,
    StorageController, Volume, VolumeNodeAssignment, NameAlias, ToolTip

  # Pick a unique cookie name to distinguish our session data from others'
  #session :key => '_nventory_session_id'
  #config.action_controller.session = { :key => '_nventory_session_id' }
  
  before_filter :check_authentication, :except => [:login,:sso]
  before_filter :check_authorization, :except => [:login,:sso]
  # Don't log passwords
  filter_parameter_logging "password"
  
  def check_authentication 
    # Always require web UI users to authenticate, so that they're
    # already authenticated if they want to make a change.  This
    # provides for a more seamless user experience.  XML users
    # don't have to authenticate unless they're making a change.
    if params[:format] && params[:format] == 'xml'
      unless params[:controller] == 'accounts'
        return true if request.get?
      end
    end
    # Only if sso setting(s) are on
    if SSO_AUTH_URL
      if (session[:account_id])
        session[:sso] = false
      else
        if @sso = sso_auth
          session[:sso] = true
          unless acct ||= Account.find_by_login(@sso.login)
            uri = URI.parse("#{SSO_AUTH_URL}#{@sso.login}")
            http = Net::HTTP::Proxy(SSO_PROXY_SERVER,SSO_PROXY_PORT).new(uri.host,uri.port)
            http.use_ssl = true
            sso_xmldata = http.get(uri.request_uri).body
            sso_xmldoc = Hpricot::XML(sso_xmldata)
            email = (sso_xmldoc/:email).innerHTML
            fname = (sso_xmldoc/'first-name').innerHTML
            lname = (sso_xmldoc/'last-name').innerHTML
            account = Account.new(:login => @sso.login,
                                  :name => "#{fname} #{lname}",
                                  :email_address => email,
                                  :password_hash => '*',
                                  :password_salt => '*')
            if (!account.save)
              # FIXME
              #errors.add
              account.errors.each { |attr,msg| logger.info "Error #{attr}: #{msg}" }
              account = nil
            end
          end
        else 
          session[:sso] = false
        end
      end # if SSO_AUTH_URL
    elsif session[:account_id]
      return true
    else
      session[:original_uri] = request.request_uri
      flash[:error] = "Please authenticate to access that page."
      redirect_to :controller => "login", :action => "login"
    end
  end

  def check_authorization
    if !request.get?
      if session[:sso]
        acct ||= Account.find_by_login(@sso.login)
      else
        acct = Account.find(session[:account_id])
      end
      if acct.nil? || !acct.admin?
        logger.info "Rejecting user for lack of admin privs"
        if params[:format] && params[:format] == 'xml'
          # Seems like there ought to be a slightly easier way to do this
          errs = ''
          xm = Builder::XmlMarkup.new(:target => errs, :indent => 2)
          xm.instruct!
          xm.errors{ xm.error('You must have admin privileges to make changes') }
          render :xml => errs, :status => :unauthorized
          return false
        else
          flash[:error] = 'You must have admin privileges to make changes'
          begin
            redirect_to :back
          # The rescue syntax here seems odd, but it works
          # http://www.ruby-forum.com/topic/85701
          rescue ::ActionController::RedirectBackError
            # This seems like a reasonable default destination in this case
            redirect_to :controller => "dashboard"
          end
          return false
        end
      end
    end
    # Give the thumb's up if we didn't find any reason to reject the user
    return true
  end
  
  # Controllers punt to this method to implement the field_names action
  def field_names(mainclass)
    fields_xml = ''
    xm = Builder::XmlMarkup.new(:target => fields_xml, :indent => 2)
    xm.instruct!
    xm.field_names{
      # Insert all of our local column names
      mainclass.content_columns.each { |column| xm.field_name("#{column.name}") }

      # Then insert all of the column names from our associations
      mainclass.reflect_on_all_associations.each do |assoc|
        # Don't expose implementation details that aren't meaningful
        # to the user
        next if assoc.name == :audits
        next if assoc.name == :utilization_metrics
        next if assoc.options.has_key?(:polymorphic)
        next if assoc.name.to_s =~ /_assignments?$/

        # Not sure yet if I want to handle second-level associations in a special way
        # It doesn't matter to the user for searching, but does potentionally matter
        # if they request an include.
        #if assoc.options.has_key?(:through) && assoc.options[:through].to_s !~ /_assignments$/
        #end
        
        assoc.klass.content_columns.each do |column|
          # If it's the column that we let the user shortcut by just
          # specifying the association (leaving off the column name)
          # then indicate that to the user by including the shortcut.
          # I could be convinced to do this in a more XMLish fashion
          # (i.e. a <field_name_shortcut> element or something) if
          # someone wanted to programatically do something with these.
          # Currently the client just dumps these out to the user so this
          # is sufficient.
          if (assoc.klass.respond_to?('default_search_attribute') &&
            column.name == assoc.klass.default_search_attribute)
            xm.field_name("#{assoc.name}[#{column.name}] (#{assoc.name})")
          else
            xm.field_name("#{assoc.name}[#{column.name}]")
          end
        end
      end
    }

    respond_to do |format|
      format.xml { render :xml => fields_xml }
    end
  end
  
  # We allow the user to request that data from associations be
  # included in the results.  This is really only useful for XML
  # users, as the HTML views will just ignore the extra data.
  def process_includes(mainclass, params_data)
    includes = {}
    errors = []
    if params_data
      include_requests = {}
      if params_data.kind_of?(Hash)
        params_data.each do |key,value|
          if value == ''
            include_requests[key] = {}
          else
            include_requests[key] = value
          end
        end
      elsif params_data.kind_of?(Array)
        params_data.each { |p| include_requests[p] = {} }
      else
        include_requests[params_data] = {}
      end

      include_requests.each do |include_request, value|
        assoc = mainclass.reflect_on_association(include_request.to_sym)
        if assoc.nil?
          # FIXME: Need better error handling for XML users
          errors << "Ignored invalid include #{include_request}"
          logger.info "Ignored invalid include #{include_request}"
          next
        else
          # Rails appears to have a bug as of 2.1.1 such that including a
          # has_one, through association causes an exception.  The exception
          # looks like this for future reference:
          # NoMethodError (undefined method `to_ary' for #<Datacenter:0x3aaa1b0>)
          if assoc.macro == :has_one && assoc.options.has_key?(:through)
            # FIXME: Need better error handling for XML users
            errors << "Ignored has_one, through include #{include_request}"
            logger.info "Ignored has_one, through include #{include_request}"
          else
            if !value.empty?
              value = process_includes(assoc.klass, value)
            end
            includes[include_request.to_sym] = value
          end
        end
      end
    end
    return includes
  end

  # find and to_xml take their :include options in different formats
  # find wants:
  # :include => { :node_rack => { :datacenter_node_rack_assignment => :datacenter } }
  # or this (which is what we use because it is easier to generate recursively)
  # :include => { :node_rack => { :datacenter_node_rack_assignment => { :datacenter => {} } } }
  # to_xml wants:
  # :include => { :node_rack => { :include => { :datacenter_node_rack_assignment => { :include => { :datacenter => {} } } } } }
  # This method takes the find format and returns the to_xml format
  def convert_includes(includes)
    includes.each do |key, value|
      unless (value.nil? || value.blank?)
        includes[key] = { :include => convert_includes(value) }
      end
    end
    includes
  end
  
  # Recursively search 'mainclass' for an association with a name matching
  # 'target_assoc'.  Returns the association that is closest to mainclass
  # in the association tree, a copy of the includes hash that is passed in
  # with the necessary hierarchy of assocations inserted so that a call to
  # 'find' with those includes could query against that association, and the
  # depth or distance in number of associations between mainclass and the
  # selected assocation.
  # For example, if mainclass were Node and target_assoc were
  # :hardware_profile then the :hardware_profile association would be
  # returned and includes would be populated with { :hardware_profile => {} }
  # Likewise, if mainclass were Node and target_assoc were :datacenter then
  # the :datacenter_node_rack_assignment association to Datacenter would be
  # returned (this method having recursively descended the
  # Node->NodeRackNodeAssignment->NodeRack->DatacenterNodeRackAssignment assocations
  # to find that association) and includes would be populated with
  # {:node_rack_node_assignment => {:rack => {:datacenter_node_rack_assignment => {:datacenter => {}}}}}
  # Note that the user may pass us an already partially populated includes
  # hash, so we need to be careful to insert any includes we add without
  # removing any that may already be in the hash structure.
  # Used by acts_as_audited
  protected
    def current_user
      if @sso = sso_auth(:redirect => false)
        @user ||= Account.find_by_login(@sso.login)
      else
        @user ||= Account.find(session[:account_id]) if session[:account_id]
      end
    end

end
