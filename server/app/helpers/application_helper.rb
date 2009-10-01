# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
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
    result = model_title(NodeRack,:datacenter,'Datacenters') if model == Datacenter
    result = model_title(nil,:audit,'Audits',audits_tooltip) if model == Audit
    result = model_title(DatabaseInstance,:name,'Database Instances') if model == DatabaseInstance 
    result = model_title(Node,:hardware_profile,'Hardware Profiles') if model == HardwareProfile 
    result = model_title(IpAddress,:network_interface,'Network Interfaces') if model == NetworkInterface 
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
    result = model_title(Node,:status,'Statuses') if model == Status 
    result = model_title(NodeGroup,:subnets,'Subnets') if model == Subnet 
    result = model_title(VipLbPoolAssignment,:vip,'VIPs') if model == Vip 
    result = model_title(VolumeNodeAssignment,:volume,'Volumes') if model == Volume 
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
  
end
