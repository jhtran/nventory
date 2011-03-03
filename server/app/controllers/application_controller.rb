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
  if MyConfig.redirect_login_to_ssl
    include SslRequirement
  end

  # Pick a unique cookie name to distinguish our session data from others'
  #session :key => '_nventory_session_id'
  #config.action_controller.session = { :key => '_nventory_session_id' }
  
  before_filter :check_authentication, :except => [:login,:sso]

  ## replaced with rails_authorization_plugin
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
        if ENV['RAILS_ENV'] == 'test'
          $loginuser ? (@sso = sso_auth(:test => $loginuser)) : (@sso = sso_auth(:test => true))
        elsif ENV['RAILS_ENV'] == 'development'
          @sso = sso_auth(:dev => true)
        else
          @sso = sso_auth
        end

        if @sso
          unless acct ||= Account.find_by_login(@sso.login)
            uri = URI.parse("#{SSO_AUTH_URL}#{@sso.login}")
            http = Net::HTTP::Proxy(SSO_PROXY_SERVER,SSO_PROXY_PORT).new(uri.host,uri.port)
            http.use_ssl = true
            sso_xmldata = http.get(uri.request_uri).body
            sso_xmldoc = Hpricot::XML(sso_xmldata)
            email = (sso_xmldoc/:email).innerHTML
            email ||= "#{@sso.login}@#{EMAIL_SUFFIX}" unless
            fname = (sso_xmldoc/'first-name').innerHTML
            lname = (sso_xmldoc/'last-name').innerHTML
            (!fname.empty? && !lname.empty?) ? (fullname = "#{fname} #{lname}") : (fullname = @sso.login)
            acct = Account.new(:login => @sso.login,
                               :name => "#{fullname}",
                               :email_address => email,
                               :password_hash => '*',
                               :password_salt => '*')
            unless acct.save
              flash[:error] = "<strong>SSO Account Auto-Create Error(s):</strong> <br /> "
              acct.errors.each do |attr,msg| 
                logger.info "Error #{attr}: #{msg}" 
                flash[:error] << "&nbsp;&nbsp* #{attr}: #{msg}"
              end
              acct= nil
            end
          end # unless acct

          unless acct
            session[:sso] = false
            redirect_to(:controller => :login,:action => :login) and return
          end

          unless acct.authz
            result = AccountGroup.find_by_name("#{acct.login}.self")
            if result 
              acct.authz = result
              acct.save
            else
              authz = AccountGroup.create({:name => "#{acct.login}.self"})
              acct.authz = authz
              authz.save
              authz.has_role 'updater', authz
              authz.has_role 'updater', acct
            end # if result
          else
            acct.authz.has_role('updater', acct.authz) unless acct.authz.has_role?('updater',authz) || acct.nil? || acct.authz.nil?
            acct.authz.has_role('updater', acct) unless acct.authz.has_role?('updater',acct) || acct.nil?
          end # unless acct.authz
          session[:sso] = true
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
        # from rails_authorization_plugin should not be searched
        next if assoc.name == :users
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

  def current_user
    if SSO_AUTH_SERVER
      if ENV['RAILS_ENV'] == 'test'
        if session[:account_id]
          @user = Account.find_by_id(session[:account_id])
        else
          $loginuser ? (@user ||= Account.find_by_login($loginuser)) : (@user ||= Account.find_by_login('testuser'))
        end
      elsif ENV['RAILS_ENV'] == 'development'
        if (@sso = sso_auth(:dev => true))
          @user ||= Account.find_by_login(@sso.login)
        end 
      elsif (@sso = sso_auth(:redirect => false))
        @user ||= Account.find_by_login(@sso.login)
      else
        @user ||= Account.find(session[:account_id]) if session[:account_id]
      end
    else
      (@user ||= Account.find(session[:account_id])) if session[:account_id]
    end
  end

  def getauth
    # sets only the @auth object without looking for a specific model/instance permit/deny
    @auth = current_user.authz
  end

  def get_obj_auth(controller=nil, refid=nil, action=nil)
    # :before_filter to get the @auth permit or deny to access each method in controller
    controller ||= params[:controller]
    refid ||= params[:id]
    action ||= params['action']
    valid_actions = %w( new edit create update destroy show )
    xmljson = true if (params[:format] && (params[:format] == 'xml' || params[:format] == 'json'))
    if xmljson
      unless controller.to_s == 'accounts'
        return true if request.get? && params[:action].to_s != 'show'
      end
    end
    (@auth = current_user.authz) if current_user
    return unless valid_actions.include?(action.to_s)
    model = controller.classify.constantize
    if action == 'new' || action == 'create'
      # hack to allow legacy perl cli user 'autoreg' during registration
      return true if current_user.login == 'autoreg' && params["foo"] == "bar"
      # if in custom_auth list, then allow to pass for now so that controller can do custom refined auth
      @object = model.new
      return true if custom_auth_controllers.include?(controller)
      filter_perms(@auth,@object,['creator','admin'])
    elsif action == 'addauth'
      refid ? (@object = model.find(refid)) : (@object = model)
      filter_perms(@auth,@object,['admin'])
    elsif action == 'show'
      includes = process_includes(model, params[:include])
      @object = model.find(refid, :include => includes) if refid
      if xmljson
        @xmlincludes = includes 
      else
        @allow_edit = true if @auth.has_role?('editor', @object) || @auth.has_role?('admin', @object)
        @allow_delete = true if @auth.has_role?('destroyer', @object) || @auth.has_role?('admin', @object)
      end
    else
      refid ? (@object = model.find(refid)) : (@object = model)
      if action == 'update' 
        return true if custom_auth_controllers.include?(controller)
        roles_users = filter_perms(@auth,@object,'updater',true,:return_roles_users)
        return if roles_users.nil?
        roles_users_attrs = roles_users.collect(&:attrs).flatten.compact
        # if a roles_user obj has no attrs specified, by default allows update to ALL attributes. 
        # however, if an attr is specified, the restriction is to ONLY ALLOW update to that attribute.
        if roles_users_attrs && !roles_users_attrs.empty?
          params[controller.singularize] ? (requested_attrs = params[controller.singularize]) : (requested_attrs = [])
          real_model_attrs = model.column_names
          requested_attrs.keys.each{ |attrb| requested_attrs.delete(attrb) unless real_model_attrs.include?(attrb) }
          requested_attrs.each_pair do |key,value|
            if @object.respond_to?(key) # if value hasn't changed, skip
              requested_attrs.delete(key) if @object.send(key).to_s == value.to_s
            end
          end
          requested_attrs.each_pair do |attrb, value|
            next if value.nil? || value.empty?
            unless roles_users_attrs.include?(attrb)
              customdenied = $denied + " to modify the attribute: #{attrb}"
              logger.info "\n\n\n****  #{customdenied} ****\n\n\n\n"
              replace_html_msg = "<font color=red>#{customdenied}</font>"
              respond_to do |format|
                format.html { flash[:error] = customdenied and redirect_to(:action => :index) and return }
                format.js { render :update do |page| page.replace_html(params[:div],replace_html_msg ) end if params[:div] }
                format.xml { render :text => customdenied and return }
              end # respond_to do |format|
            end # if !roles_users_attrs.include?(attrb)
          end # requested_attrs.each_pair do |attrb, value|
        end # if roles_users_attrs
        return true unless roles_users.nil? || roles_users.empty?
      elsif action == 'edit'
        return true if custom_auth_controllers.include?(controller)
        filter_perms(@auth,@object,'updater')
      elsif action == 'destroy'
        return true if custom_auth_controllers.include?(controller)
        filter_perms(@auth,@object,['destroyer'])
      end
    end
  end

  $denied = "Permission Denied.  You do not have the proper authorization"

  def filter_perms(user,obj,perms,willrender=true,*others)
    roles_users_flag = false
    found_roles_users = []
    # var to return the roles_users instead of just true
    return_roles_users = true if  others.include?(:return_roles_users)

    # shortcut to detect if user's account_group and any of its inherited parent_groups have admin privilege
    # first see if user account already has the right perms before looking at inheritance
    if ( user.has_role?('admin',obj) ) 
      return true unless return_roles_users
      roles = obj.allowed_roles.select{|a| a.name == 'admin'}
      roles.each{|role| role.roles_users.each{|roles_user| found_roles_users << roles_user if roles_user.account_group == user  } }
      roles_users_flag = true
    end
    perms.each do |perm| 
      next if perm == 'admin' # we've already processed this one
      if user.has_role?(perm,obj)
        return true  unless return_roles_users
        roles = obj.allowed_roles.select{|a| a.name == perm}
        roles.each{|role| role.roles_users.each{|roles_user| found_roles_users << roles_user if roles_user.account_group == user  } }
        roles_users_flag = true
      end # if user.has_role?(perm,obj)
    end

    # now check inheritance from account_groups
    all_parent_roles = {}
    user.self_group_parents.each{|parent_group| parent_group.roles.each{|role| all_parent_roles[role] = parent_group}}
    # if obj is a node|node_group, can inherit pemissions from parent node_groups  ** I SEE SOME OPTIMIZING IN THE FUTURE **
    if obj.kind_of?(Node) || obj.kind_of?(NodeGroup)
      ngs = obj.all_parent_groups
      inherited_roles = []
      ngs.each do |ng|
        ng.accepted_roles.each do |ar| 
          ar.roles_users.each do |ru| 
            if ru.account_group.name !~ /\.self$/
              if ru.account_group.all_self_groups.include?(user)
                inherited_roles << ar unless inherited_roles.include?(ar)
              end
            end # if ru.account_group.name !~ /\.self$/
          end # ar.roles_users.each do |ru|
        end # ng.accepted_roles.each do |ar|
      end # ngs.each do |ng|
    end # if obj.kind_of?(Node) || obj.kind_of?(NodeGroup)
   
    perms.each do |perm|
      # inherit auth from account_groups
      all_parent_roles.each_pair do |role, parent_group|
        if (role.name == 'admin' || role.name == perm ) && !role.authorizable && !role.authorizable_type
          return true unless return_roles_users
          roles_users_flag = true
        end
        if role.authorizable_id.nil?
          obj.kind_of?(Class) ? (authorizable_class = obj.to_s) : (authorizable_class = obj.class.to_s)
          if (role.name == 'admin' || role.name == perm ) && (role.authorizable_type == authorizable_class)
            return true unless return_roles_users
            role.roles_users.each{|roles_user| (found_roles_users << roles_user) if roles_user.account_group == parent_group}
            roles_users_flag = true
          end #  if (role.name == 'admin' || role.name == perm ) && (role.authorizable_type == authorizable_class) )
        end # if role.authorizable_id.nil?
        if (role.name == 'admin' || role.name == perm ) && (role.authorizable == obj)
          return true unless return_roles_users
          role.roles_users.each{|roles_user| (found_roles_users << roles_user) if roles_user.account_group == parent_group}
          roles_users_flag = true
        end
      end

      if obj.kind_of?(Node) || obj.kind_of?(NodeGroup)
        # inherit auth from node_group parents
        ngs.each do |ng| 
          if user.has_role?('admin',ng) 
            return true unless return_roles_users
            roles = obj.allowed_roles.select{|a| a.name == 'admin'}
            roles.each{|role| role.roles_users.each{|roles_user| found_roles_users << roles_user if roles_user.account_group == ng} }
            roles_users_flag = true
          end
          if user.has_role?(perm,ng) 
            return true unless return_roles_users
            roles = obj.allowed_roles.select{|a| a.name == perm}
            roles.each{|role| role.roles_users.each{|roles_user| found_roles_users << roles_user if roles_user.account_group == user  } }
            roles_users_flag = true
          end
        end
        inherited_roles.each do |role|
          next unless role.authorizable
          if (role.name == 'admin' || role.name == perm )
            return true unless return_roles_users
            role.roles_users.each{|roles_user| found_roles_users << roles_user if roles_user.account_group == user}
            roles_users_flag = true
          end
        end
      end
    end # perms.each do |perm|

    # if hasn't returned by now, access deny
    return found_roles_users if roles_users_flag
    return false if willrender == false

    obj.kind_of?(Class) ? label = Class.to_s : label = "#{obj.class.to_s} Object"

    replace_html_msg = "<font color=red><strong>#{$denied} on #{label} as #{perms.kind_of?(Array) ? perms.join(',') : perms }</strong></font>" 
    respond_to do |format|
      format.html { flash[:error] = $denied and redirect_to(:action => :index) and return }
      format.js { render :update do |page| page.replace_html(params[:div],replace_html_msg ) end if params[:div] }
      format.xml { render :text => $denied and return }
    end # respond_to do |format|
  end

  def list_models
    %w( Node NodeGroup Account AccountGroup Comment DatabaseInstance Datacenter Drive HardwareProfile IpAddress LbPool LbProfile NameAlias NetworkInterface NetworkPort 
        NodeRack OperatingSystem Outlet Service ServiceProfile Status StorageController Subnet ToolTip Vip Volume Tag Graffiti )
  end

  def custom_auth_controllers
    %w(node_group_node_assignments node_group_node_group_assignments node_group_vip_assignments name_aliases volume_node_assignments volumes datacenter_node_rack_assignments
       service_service_assignments lb_pool_node_assignments node_group_vip_assignments node_rack_node_assignments taggings
       account_group_account_group_assignments ip_address_network_port_assignments account_group_self_group_assignments datacenter_vip_assignments
       node_database_instance_assignments virtual_assignments volume_drive_assignments vip_lb_pool_assignments)
  end

  def modelperms
    # Get a hash of current user's permissions for each model class
    @modelperms = {}
    return unless @auth
    list_models.each { |model| @modelperms[model.to_s] = filter_perms(@auth,model.constantize,['admin','creator'],false) }
  end

  def get_perms
    # List all permissions for an object or model class
    model = params[:controller].classify.constantize
    if params[:id]
      # instance
      @object = model.find(params[:id])
    else
      # assume is a Model class
      @object = model
    end
    @objects = @object.allowed_roles
    # inherited from parent_node_groups (only if Node or NodeGroup)
    parentperms = build_parentperms(@object)
    respond_to do |format|
      format.js {
        render(:update) { |page|
          page.replace_html 'perms', :partial => 'shared/perms_table', :locals => {:perms => @objects, :refid => params[:id], :parentperms => parentperms}
        }
      }
    end
  end

  def get_roles_accounts
    params[:refcontroller] ? (refcontroller = params[:refcontroller]) : (refcontroller = controller.controller_name)
    @useraccs = AccountGroup.self_scope.find(:all, :select => "id,name").collect{|useracc| [useracc.name.sub(/\.self$/,''), useracc.id]}.sort{|a,b| a[0].downcase<=>b[0].downcase}.unshift(['Users:', ''])
    @groupaccs = AccountGroup.def_scope.find(:all, :select => "id,name").collect{|useracc| [useracc.name.sub(/\.self$/,''), useracc.id]}.sort{|a,b| a[0].downcase<=>b[0].downcase}.unshift(['Groups:', ''])
    @attrs = refcontroller.camelize.singularize.constantize.attrs.sort{|a,b| a[1] <=> b[1]}.unshift(["#{refcontroller.singularize.capitalize} Attributes:",''])
    @rolenames = Role.role_names.collect{|rn| [rn, rn]}
    respond_to do |format|
      format.js {
        render(:update) { |page|
          page.replace_html 'perms', :partial => 'shared/add_perm', :locals => {:useraccs => @useraccs, :refcontroller => refcontroller, :refid => params[:refid]}
        }
      }
    end
  end

  # deletes a user permission from an obj
  def delauth
    controller = params[:controller]
    model = controller.classify.constantize
    params[:refid] ? (@object = model.find(params[:refid])) : (@object = model)
    if filter_perms(@auth,@object, ['admin'])
      roles_user = RolesUser.find(params[:roles_user_id])
      useracc = roles_user.account_group
      role_name = roles_user.role.name
      @object.accepts_no_role role_name, useracc
      objects = @object.allowed_roles
      parentperms = build_parentperms(@object)
  
      respond_to do |format|
        format.js {
          render(:update) { |page|
            page.replace_html 'perms', :partial => 'shared/perms_table', :locals => { :perms => objects, :refid => params[:refid], :parentperms => parentperms }
          }
        }
      end
    end
  end

  def addauth
    controller = params[:controller]
    model = controller.classify.constantize
    userids = params[controller]['useraccs'].compact.reject(&:blank?)
    params[controller]['groupaccs'].compact.reject(&:blank?).each{|groupid| userids << groupid}
    attrs = params[controller]['attrs'].compact.reject(&:blank?)
    if params[controller][:refid] && !params[controller][:refid].empty?
      refid = params[controller][:refid]
      @object = model.find(refid) 
    else
      @object = model
    end
    if filter_perms(@auth,@object, ['admin'])
      unless userids.empty?
        useraccs = AccountGroup.find(userids) 
        useraccs.each{ |useracc| @object.accepts_role params[controller][:role], useracc, attrs }
      end
    end
    objects = @object.allowed_roles
    parentperms = build_parentperms(@object)

    respond_to do |format|
      format.js { render(:update) { |page| page.replace_html 'perms', :partial => 'shared/perms_table', :locals => { :perms => objects, :refid => refid, :parentperms => parentperms } } }
    end
  end

  def build_parentperms(srcobj)
    # inherited from parent_node_groups (only if Node or NodeGroup)
    allobjs = srcobj.allowed_roles.dup
    parentperms = {}
    if srcobj.kind_of?(NodeGroup) || srcobj.kind_of?(Node)
      srcobj.all_parent_groups.each do |png|
        parentperms[png] = []
        png.allowed_roles.each do |role|
          unless allobjs.include?(role)
            parentperms[png] << role
          end
        end
      end
    end
    return parentperms
  end

end
