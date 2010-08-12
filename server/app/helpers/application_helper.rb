# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  include TagsHelper
  
  # borrowed from Simply Restful (would rather not import the whole plugin) 
  def dom_id(record, prefix = nil) 
    prefix ||= 'new' unless record.id 
    [ prefix, singular_class_name(record), record.id ].compact * '_'
  end
  
  def singular_class_name(record_or_class)
    class_from_record_or_class(record_or_class).name.underscore.tr('/', '_')
  end
  
  def sort_td_class_helper(param)
    result = 'class="sortup"' if params[:sort] == param
    result = 'class="sortdown"' if params[:sort] == param + "_reverse"
    return result
  end
  
  def sort_link_helper(text, param)
    key = param
    key += "_reverse" if params[:sort] == param
    options = {
        :url => {:action => 'index', :params => params.merge({:sort => key, :page => nil})},
        :method => :get
    }
    html_options = {
      :title => "Sort by this field",
      :href => url_for(:action => 'index', :params => params.merge({:sort => key, :page => nil}))
    }
    link_to(text, options, html_options)
  end  

  def tooltip(model,field,title=nil,description=nil)
    # a) field must be specified even if you don't want to search from a model, it is used as the div id
    # b) if u dont' want to pull from ToolTip model, you have to at least specify the field and description 
    return unless field
    increment = rand(1000).to_s
    title = field.to_s.titleize if title.nil?
    span = "<span id='" + field.to_s + increment + "_tooltag'>" + title + '</span>'

    # if no model, then it's not a ToolTip call but we need description at least.  If no description, then no mousover script
    return title if model.nil? && description.nil?

    # has model, so we need to query ToolTip for the descrption to create mousover 
    if model
      result = ToolTip.find_by_model_and_attr(model.to_s,field.to_s)
      return title if result.nil? || !result.description
    end # if model.nil? || field.nil?

    if ( description && !description.blank? ) then
      linewrap_description = line_wrap(description.to_s)
    elsif result.description then
      linewrap_description = line_wrap(result.description.to_s)
    end

    # now create the tooltip javascript content
    tt = "<div id='" + field.to_s + increment + "_toolbox' style='display:none; padding: 15px; background-color: yellow'>" +
         linewrap_description +
         "</div>\n" +
         '<script type="text/javascript">' +
         "var my_tooltip = new Tooltip('" + field.to_s + increment + "_tooltag', '" + field.to_s + increment + "_toolbox')" +
         "</script>\n"
    @tooltips << tt

    return span
  end

  def dashboard_pulldown_form_for_model(search_class, collection)
    model_class = collection.first.class
    return '<form action="' + search_class.to_s.tableize + '" method="get">' +
    '&nbsp;&nbsp;&nbsp;<select style="width:20em;" id="exact_'+model_class.to_s.underscore+'" name="exact_'+model_class.to_s.underscore+'" onchange="if (this.value != \'\') this.form.submit();">' +
    '<option value="">By: ' + model_class.to_s.underscore.titleize + '</option>' +
    options_from_collection_for_select(collection, 'name', 'name') +
    '</select>' +
    '</form>'
  end

  def list_reports
    return ReportsController.new.list_reports
  end

  def logged_in_account
    if session[:sso]
      Account.find_by_login(@sso.login)
    else 
      Account.find(session[:account_id])
    end
  end

  def sso_obj
    @sso
  end
  
  private
  def class_from_record_or_class(record_or_class)
    record_or_class.is_a?(Class) ? record_or_class : record_or_class.class
  end

  def nodes_tooltip
    "Any single pc/network/hardware unit.<br/>  The basic unit of nVentory in which everything revolves around"
  end
  def tooltips_tooltip
    "Content responsible for populating all of the mousover tooltip data across the nVentory web GUI"
  end
  def audits_tooltip
    "Any additions/changes to the nVentory database"
  end
  def comments_tooltip
    "User contributable comments"
  end

  def root_model_tooltip(model)
    result = tooltip(Account,:login,'Accounts') if model == Account
    result = tooltip(NodeRack,:datacenter,'Datacenters') if model == Datacenter
    result = tooltip(NodeGroup,:tags,'Tags') if model == Tag
    result = tooltip(nil,:audit,'Audits',audits_tooltip) if model == Audit
    result = tooltip(DatabaseInstance,:name,'Database Instances') if model == DatabaseInstance 
    result = tooltip(Node,:hardware_profile,'Hardware Profiles') if model == HardwareProfile 
    result = tooltip(IpAddress,:network_interface,'Network Interfaces') if model == NetworkInterface 
    result = tooltip(Node,:lb_pools,'Load Balancer Pool') if model == LbPool 
    result = tooltip(Node,:node_groups,'Node Group') if model == NodeGroup 
    result = tooltip(Node,:node_rack,'Racks') if model == NodeRack 
    result = tooltip(nil,:nodes,'Nodes',nodes_tooltip) if model == Node 
    result = tooltip(nil,:nodes,'Comments',comments_tooltip) if model == Comment
    result = tooltip(nil,:tooltips,'Tool Tips',tooltips_tooltip) if model == ToolTip
    result = tooltip(Node,:operating_system,'Operating Systems') if model == OperatingSystem 
    result = tooltip(Node,:produced_outlets,'Outlets') if model == Outlet 
    result = tooltip(Service,:service_profile,'Service Profiles') if model == ServiceProfile 
    result = tooltip(Node,:services,'Services') if model == Service 
    result = tooltip(Node,:status,'Statuses') if model == Status 
    result = tooltip(NodeGroup,:subnets,'Subnets') if model == Subnet 
    result = tooltip(VipLbPoolAssignment,:vip,'VIPs') if model == Vip 
    result = tooltip(VolumeNodeAssignment,:volume,'Volumes') if model == Volume 
    result ? (return result) : (return false)
  end

  def model_title(model,field,title=nil,description=nil)
    # a) field must be specified even if you don't want to search from a model, it is used as the div id
    # b) if u dont' want to pull from ToolTip model, you have to at least specify the field and description 
    title = field.to_s.titleize if title.nil?

    # if no model, then it's not a ToolTip call but we need description at least.  If no description, then no mousover script
    return title if model.nil? && description.nil?

    # has model, so we need to query ToolTip for the descrption to create mousover 
    if model 
      result = ToolTip.find_by_model_and_attr(model.to_s,field.to_s)
      return title if result.nil? || !result.description 
      return result.description
    else
      return description
    end
  end

  def mtitle(model)
    result = model_title(Account,:login,'Accounts') if model == Account
    result = model_title(AccountGroup,:name,'Accounts') if model == AccountGroup
    result = model_title(NodeRack,:datacenter,'Datacenters') if model == Datacenter
    result = model_title(nil,:audit,'Audits',audits_tooltip) if model == Audit
    result = model_title(DatabaseInstance,:name,'Database Instances') if model == DatabaseInstance 
    result = model_title(Node,:hardware_profile,'Hardware Profiles') if model == HardwareProfile 
    result = model_title(IpAddress,:network_interface,'Network Interfaces') if model == NetworkInterface 
    result = model_title(IpAddress,:address,'IP Address') if model == IpAddress
    result = model_title(NetworkPort,:port,'Network Port') if model == NetworkPort
    result = model_title(Drive,:name,'Drive') if model == Drive 
    result = model_title(Node,:lb_pools,'Load Balancer Pool') if model == LbPool 
    result = model_title(Node,:node_groups,'Node Group') if model == NodeGroup 
    result = model_title(Node,:node_rack,'Racks') if model == NodeRack 
    result = model_title(nil,:nodes,'Nodes',nodes_tooltip) if model == Node 
    result = model_title(nil,:nodes,'Comments',comments_tooltip) if model == Comment
    result = model_title(nil,:tooltips,'Tool Tips',tooltips_tooltip) if model == ToolTip
    result = model_title(Node,:operating_system,'Operating Systems') if model == OperatingSystem 
    result = model_title(Node,:produced_outlets,'Outlets') if model == Outlet 
    result = model_title(Service,:service_profile,'Service Profiles') if model == ServiceProfile 
    result = model_title(Node,:services,'Services') if model == Service 
    result = model_title(StorageController,:name,'StorageController') if model == StorageController
    result = model_title(Node,:status,'Statuses') if model == Status 
    result = model_title(NodeGroup,:subnets,'Subnets') if model == Subnet 
    result = model_title(VipLbPoolAssignment,:vip,'VIPs') if model == Vip 
    result = model_title(VolumeNodeAssignment,:volume,'Volumes') if model == Volume 
    result = model_title(NodeGroup,:tags,'Tags') if model == Tag
    return result.gsub(/(<br \/>|<br\/>)/, "\n")
  end

  def line_wrap(description)
    content = []
    counter = 1
    if description.size > 160
      while description.size > 160
        match = description.match(/(?:(?!(<br\s+\/>)).){1,150}/).to_s
        content << match
        description = description.sub(/(?:(?!(<br\s+\/>)).){1,150}/, '').to_s
        description = description.sub(/^<br\s+\/>/,'')
        counter += 1
      end
      content = content.join('<br />')
    else 
      content = description
    end
    return content
  end

  def csv_adv_fields(modelclass)
    all = {}
    columns = modelclass.column_names.each{ |a| all[a.to_s] = 1 }
    reflections = modelclass.reflections.keys.each{ |a| all[a.to_s] = 1 }
    all.keys.each do |attr|
      all.delete(attr.to_s) if attr.to_s =~ /(_id$|assignment|utilization|audits|roles)/i
    end
    return all.keys.sort
  end

  def allow_perm(obj,perms)
    perms = [ perms ] if perms.kind_of?(String)
    if obj.nil? # a nil obj assumes a global role
      return true if @auth.has_role?('admin')
    else
      return true if @auth.has_role?('admin', obj)
    end

    if perms.kind_of?(String)
      allperms = [perms]
    elsif perms.kind_of?(Array)
      allperms = perms
    end

    allperms.each do |perm|
      next if perm == 'admin' # we've already done this on 1st line
      return true if @auth.has_role?(perm, obj)
    end

    # check the parent_groups' roles for inheritance
    all_parent_roles = []
    @auth.self_group_parents.each{|parent_group| all_parent_roles << parent_group.roles}
    all_parent_roles.flatten!
    # if obj is a node|node_group, can inherit pemissions from parent node_groups  ** I SEE SOME OPTIMIZING IN THE FUTURE **
    if obj.kind_of?(Node) || obj.kind_of?(NodeGroup)
      ngs = obj.all_parent_groups
      inherited_roles = []
      ngs.each do |ng|
        ng.accepted_roles.each do |ar|
          ar.roles_users.each do |ru|
            if ru.account_group.name !~ /\.self$/
              if ru.account_group.all_self_groups.include?(@auth)
                inherited_roles << ar unless inherited_roles.include?(ar)
              end
            end # if ru.account_group.name !~ /\.self$/
          end # ar.roles_users.each do |ru|
        end # ng.accepted_roles.each do |ar|
      end # ngs.each do |ng|
    end # if obj.kind_of?(Node) || obj.kind_of?(NodeGroup)

    perms.each do |perm|
      # inherit auth from account_groups
      all_parent_roles.each do |role|
        return true if (role.name == 'admin' || role.name == perm ) && !role.authorizable && !role.authorizable_type
        if obj.kind_of?(Class)
          return true if (role.name == 'admin' || role.name == perm ) && (role.authorizable_type == obj.to_s) && role.authorizable_id.nil?
        else
          return true if (role.name == 'admin' || role.name == perm ) && (role.authorizable_type == obj.class.to_s) && role.authorizable_id.nil?
        end
        return true if (role.name == 'admin' || role.name == perm ) && (role.authorizable == obj)
      end
      # if obj is node or node_group, can inherit auth from node_groups
      if obj.kind_of?(Node) || obj.kind_of?(NodeGroup)
        # inherit auth from node_group parents
        ngs.each{|ng| return true if ( @auth.has_role?('admin',ng) || @auth.has_role?(perm,ng) )}
        inherited_roles.each do |role|
          next unless role.authorizable
          return true if (role.name == 'admin' || role.name == perm )
        end
      end
    end # perms.each do |perm|
    
    return false
  end

  def perms_classify(srcobj,perm,roles_user)
    data = {}

    if roles_user.account_group.name =~ /\.self$/ 
      usertag = "#{link_to(roles_user.account_group.authz.login, roles_user.account_group.authz)} #{image_tag('user-icon.png', :alt => 'usericon')}"
    else
      usertag = "#{link_to(roles_user.account_group.name, roles_user.account_group)} #{image_tag('user-group-icon.png', :alt => 'usergroupicon')}"
    end

    srcobj.kind_of?(Class) ? (srcclass = 'Class') : (srcclass = 'instance')
    if perm.authorizable.nil? && perm.authorizable_type.nil?
      permclass = 'Global'
      permtag = permclass
    elsif perm.authorizable.nil? && !perm.authorizable_type.nil?
      permclass = 'Class'
      permtag = link_to("#{perm.authorizable_type} Class", url_for(:controller => perm.authorizable_type.tableize))
    elsif perm.authorizable && perm.authorizable_type
      permclass = 'instance'
      # when node_group inheritance from parent node_group, should link if the srcobj(currentview) isn't the authorized role obj (parent_group)
      if perm.authorizable == srcobj
        permtag = "#{perm.authorizable.send(perm.authorizable.class.default_search_attribute)}"
      else
        permtag = link_to( "#{perm.authorizable.send(perm.authorizable.class.default_search_attribute)}",perm.authorizable)
      end
    else
      permclass = 'unknown'
    end

    if roles_user.attrs
      attrstag = "<font color=green><ul>"
      roles_user.attrs.each{|attr| attrstag << "<li>#{attr.sub(/_id$/,'')}</li>"}
      attrstag << "</ul></font>"
    end

    params[:refcontroller] ? (refcontroller = params[:refcontroller]) : (refcontroller = controller.controller_name)
    params[:refid] ? (refid = params[:refid]) : (refid = @object.id unless @object.kind_of?(Class))

    if permclass == srcclass 
      # when node_group inheritance from parent node_group, shouldnt allow deletion if the srcobj(currentview) isn't the authorized role obj (parent_group)
      if (srcclass == 'instance') && (perm.authorizable == srcobj)
        deletetag = link_to_remote 'Delete', 
                      {:url => {:action => :delauth, :roles_user_id => roles_user.id, :refcontroller => refcontroller, :refid => refid },
                       :confirm => 'Are you sure?'}
      elsif srcclass == 'Class'
        deletetag = link_to_remote 'Delete', 
                      {:url => {:action => :delauth, :roles_user_id => roles_user.id, :refcontroller => refcontroller }, 
                       :confirm => 'Are you sure?'}
      end
    else
      delete = ""
    end

    data[:usertag] = usertag
    data[:deletetag] = deletetag
    data[:permtag] = permtag
    attrstag ? (data[:attrstag] = attrstag) : (data[:attrstag] = '<ul><font color=green>All</font></ul>')
    return data
  end

  def roles_classify(account_group,role)
    data = {}
    
    if role.authorizable.nil? && role.authorizable_type.nil?
      roleclass = 'Global'
      roletag = roleclass
    elsif role.authorizable.nil? && !role.authorizable_type.nil?
      roleclass = 'Class'
      roletag = link_to("#{role.authorizable_type} Class", url_for(:controller => role.authorizable_type.pluralize.underscore))
    elsif role.authorizable && role.authorizable_type
      roleclass = 'instance'
      roletag = link_to(role.authorizable.send(role.authorizable.class.default_search_attribute), role.authorizable)
    else
      roleclass = 'unknown'
    end

    roles_user = RolesUser.find_by_account_group_id_and_role_id(account_group.id, role.id)
    deletetag = link_to_remote 'Remove', 
                     {:url => {:controller => 'account_groups', :action => :removeauth, 
                      :id => account_group.id, :refid => roles_user.id},
                      :confirm => 'Are you sure?'} if allow_perm(role.authorizable,role.name)

    data[:roletag] = roletag
    data[:deletetag] = deletetag

    return data
  end

end
