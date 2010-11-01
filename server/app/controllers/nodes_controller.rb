class NodesController < ApplicationController
  # sets the @auth object and @object
  before_filter :get_obj_auth
  # to populate the sidebar links if ablity to create new objects for each model/controller
  before_filter :modelperms

  # GET /nodes
  # GET /nodes.xml
  def index
    # Turns on csv export form on
    @csvon = "true"
    params[:csv] = true
    special_joins = {
      'preferred_operating_system' =>
        'LEFT OUTER JOIN operating_systems AS preferred_operating_systems ON nodes.preferred_operating_system_id = preferred_operating_systems.id'
    }
   
    
    ## BUILD MASTER HASH WITH ALL SUB-PARAMS ##
    allparams = {}
    allparams[:mainmodel] = Node
    allparams[:webparams] = params
    allparams[:special_joins] = special_joins
    results = Search.new(allparams).search
    
    flash[:error] = results[:errors].join('<br />') unless results[:errors].empty?
    includes = results[:includes]
    results[:requested_includes].each_pair{|k,v| includes[k] = v}
    @objects = results[:search_results]
    
    # search results should contain csvobj which contains all the params for building and put it in session.  View will launch csv controller to call on that session
    if @csvon == "true"
      results[:csvobj]['def_attr_names'] = Node.default_includes
      session[:csvobj] = results[:csvobj] 
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml do 
        logger.info "XML INCLUDES:\n" + includes.to_yaml
        if params[:inline] == "off"
          xmlobj = @objects.to_xml(:include => convert_includes(includes), :dasherize => false)
          send_data(xmlobj)
        else
          render :xml => @objects.to_xml(:include => convert_includes(includes),
                                                   :dasherize => false)
        end
      end
      format.csv do
        if params[:inline] == "off"
          send_data(@objects)
        else
          send_data(@objects, :type => 'text/plain', :disposition => 'inline')
        end
      end
    end
  end

  # GET /nodes/1
  # GET /nodes/1.xml
  def show
    @node = @object
    @parent_services = @node.services.collect { |ng| ng.parent_services }.flatten
    @child_services = @node.services.collect { |ng| ng.child_services }.flatten
    logins = UtilizationMetric.find(:all,:select => :value, :include => {:node => {},:utilization_metric_name=> {}}, 
					:conditions => ["nodes.id = ? and utilization_metric_names.name = ? and assigned_at like ?", @node.id, 'login_count', "%#{Time.now.strftime("%Y-%m-%d")}%"])
    @logins_today = logins.collect{|login| login.value.to_i}.sum
    percent_cpus = UtilizationMetric.find(:all,:select => :value, :include => {:node => {},:utilization_metric_name=> {}}, 
					:conditions => ["nodes.id = ? and utilization_metric_names.name = ? and assigned_at like ?", @node.id, 'percent_cpu', "%#{Time.now.strftime("%Y-%m-%d")}%"])
    unless percent_cpus.empty? 
      @percent_cpu_today = percent_cpus.collect{|each| each.value.to_i}.sum.to_i / percent_cpus.size.to_i 
    else
      @percent_cpu_today = "No data"
    end

    respond_to do |format|
      format.html { @cpu_percent_chart = open_flash_chart_object(500,300, url_for( :action => 'show', :graph => 'cpu_percent_chart', :format => :json )) }
      format.xml  { render :xml => @node.to_xml(:include => convert_includes(@xmlincludes),
                                                      :dasherize => false) }
      format.json {
        case params[:graph]
          when 'cpu_percent_chart'
            chart = cpu_percent_chart_method
            render :text => chart.to_s
        end
      } # format.json
    end

  end

  # GET /nodes/new
  def new
    @node = @object
    respond_to do |format|
      format.html # show.html.erb
      format.js  { render :action => "inline_new", :layout => false }
    end
  end

  # GET /nodes/1/edit
  def edit
    @node = @object
  end

  # POST /nodes
  # POST /nodes.xml
  def create
    # PS-441 & PS-306 legacy field no longer used
    params[:node].delete(:virtual_client_ids) if params[:node][:virtual_client_ids]
    params[:node].delete(:virtual_parent_node_id) if params[:node][:virtual_parent_node_id]
    # If the user didn't specify an operating system id then find or
    # create one based on the OS info they did specify.
    if !params[:node].include?(:operating_system_id)
      if params.include?(:operating_system)
        params[:node][:operating_system_id] = find_or_create_operating_system().id
      end
    end
    # If the user didn't specify a hardware profile id then find or
    # create one based on the hardware info they did specify.
    if !params[:node].include?(:hardware_profile_id)
      params[:node][:hardware_profile_id] = find_or_create_hardware_profile().id
    end
    # If the user didn't specify a status id then find or
    # create one based on the status info they did specify.
    # If they didn't specify any status info then default to
    # 'setup'.
    if !params[:node].include?(:status_id)
      status = nil
      if params.include?(:status) and !params[:status][:name].blank?
        status = Status.find_or_create_by_name(params[:status][:name].to_s)
      else
        status = Status.find_or_create_by_name('setup')
      end
      params[:node][:status_id] = status.id
    end
    
    # If the user included outlet names pull them out for later application
    outlet_names = nil
    if params[:node].include?(:outlet_names)
      outlet_names = params[:node][:outlet_names]
      params[:node].delete(:outlet_names)
    end

    if params[:node].include?(:virtualmode)
      virtual_guest = true
      params[:node].delete(:virtualmode)
    end

    @node = Node.new(params[:node])

    respond_to do |format|
      if @node.save
        # If the user specified some network interface info then handle that
        # We have to perform this after saving the new node so that the
        # NICs can be associated with it.
        virtual_guest ? process_network_interfaces(:noswitch) : process_network_interfaces
        process_storage_controllers
        # If the user specified a rack assignment then handle that
        process_rack_assignment
        # If the user included outlet names apply them now
        if outlet_names
          @node.update_outlets(outlet_names)
        end
        # Process percent_cpu metrics
        process_utilization_metrics if (params["utilization_metric"])
	# Process volumes
	process_volumes if (params["volumes"])
	process_name_aliases if (params["name_aliases"])
        
        flash[:notice] = 'Node was successfully created.'
        format.html { redirect_to node_url(@node) }
        format.js { 
          render(:update) { |page| 
            
            # Depending on where the Ajax node creation comes from
            # we do something slightly different.
            if request.env["HTTP_REFERER"].include? "node_racks"
              page.replace_html 'create_node_assignment', :partial => 'shared/create_assignment', :locals => { :from => 'node_rack', :to => 'node' }
              page['node_rack_node_assignment_node_id'].value = @node.id
            end
            
            page.hide 'new_node'
            
            # WORKAROUND: We have to manually escape the single quotes here due to a bug in rails:
            # http://dev.rubyonrails.org/ticket/5751
            page.visual_effect :highlight, 'create_node_assignment', :startcolor => "\'"+RELATIONSHIP_HIGHLIGHT_START_COLOR+"\'", :endcolor => "\'"+RELATIONSHIP_HIGHLIGHT_END_COLOR+"\'", :restorecolor => "\'"+RELATIONSHIP_HIGHLIGHT_RESTORE_COLOR+"\'"
            
          }
        }
        format.xml  { head :created, :location => node_url(@node) }
      else
        format.html { render :action => "new" }
        format.js   { render(:update) { |page| page.alert(@node.errors.full_messages) } }
        format.xml  { render :xml => @node.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /nodes/1
  # PUT /nodes/1.xml
  def update
    # PS-441 & PS-306 legacy field no longer used
    if params[:node]
      params[:node].delete(:virtual_client_ids) if params[:node][:virtual_client_ids]
      params[:node].delete(:virtual_parent_node_id) if params[:node][:virtual_parent_node_id]
    end

    xmloutput = {}
    xmlinfo = [""]
    @node = @object

    # If the user is just setting a value related to one of the
    # associated models then params might not include the :node
    # key.  Rather than check for and handle that in multiple
    # places below just stick in the key here.
    if !params.include?(:node)
      params[:node] = {}
    end

    # If the user didn't specify an operating system id but did specify
    # some operating system data then find or create an operating
    # system based on the info they did specify.
    if !params[:node].include?(:operating_system_id)
      # FIXME: This should allow the user to specify only the field(s)
      # they want to change, and fill in any missing fields from the
      # node's current OS.  I.e. if the user just wanted to change the
      # OS version they shouldn't have to also specify the variant,
      # architecture, etc.
      if params.include?(:operating_system)
        params[:node][:operating_system_id] = find_or_create_operating_system().id
      end
    end
    # If the user didn't specify a hardware profile id but did specify
    # some hardware profile data then find or create a hardware
    # profile based on the info they did specify.
    if !params[:node].include?(:hardware_profile_id)
      # FIXME: This should allow the user to specify only the field(s)
      # they want to change, and fill in any missing fields from the
      # node's current hardware profile.
      if params.include?(:hardware_profile)
        params[:node][:hardware_profile_id] = find_or_create_hardware_profile().id
      end
    end
    # If the user didn't specify a status id but did specify a status name
    # then find or create a status based on the name.
    if !params[:node].include?(:status_id)
      if params.include?(:status) and !params[:status][:name].blank?
        status = Status.find_or_create_by_name(params[:status][:name].to_s)
        params[:node][:status_id] = status.id
      end
    end

    if params[:node][:virtualarch]
      if params[:node][:virtualmode]
        if params[:node][:virtualmode] == 'guest'
          virtual_guest = true
          # use switch ip & port info to find out who the vm host is
          vmhost = find_vm_host
          unless vmhost.nil?
            if vmhost.virtual_host?
              # does node belong to ANY vmvirt_assignment?  (can only belong to ONE at any time as a guest)
              results = VirtualAssignment.find(:all,:conditions => ["child_id = ?", @node.id])
              if results.empty?
                xmlinfo << "Virtual assignment to #{vmhost.name} doesn't exist.  Creating..."
                VirtualAssignment.create( :parent_id => vmhost.id, :child_id => @node.id)
              else
                xmlinfo << "#{@node.name} already assigned to virtual host #{results.first.virtual_host.name}.\n    - Skipping vm guest assignment registration."
              end
            else
              xmlinfo << "Found vmhost (#{vmhost.name}) but not registered in nventory as a vmhost.\nCancelled virtual assignment"
            end
          else
            xmlinfo << "Was unable to find a vmhost associated to the switch and switch port."
          end
        elsif params[:node][:virtualmode] == 'host'
          # register all guest vms from value passed from cli
          if params[:vmguest].kind_of?(Hash)
            vmguests = params[:vmguest]
            # clear this out of hash or will try to register a non-existing table column
            # try to find each node if exists in nventory, if does then see if virtual assign exists to this vm host, if not create it
            vmguests.keys.each do |vmguest|
              vmresults = Node.find(:all,:conditions => ["name like ?","#{vmguest}%"])
              if vmresults.size == 1
                vmnode = vmresults.first
                # Update fs size if diff
                vmnode.update_attributes(:vmimg_size => vmguests[vmguest]["vmimg_size"].to_i) 
                vmnode.update_attributes(:vmspace_used => vmguests[vmguest]["vmspace_used"].to_i) 
                # Check if a virtual machine assignment (host <=> guest) previously exists
                vmassign_results = VirtualAssignment.find(:all,:conditions => ["child_id = ?", vmnode.id])
                if vmassign_results.size > 1
                  xmlinfo << "#{vmguest} already registered to MULTIPLE vm hosts\n    (Illegal registration!) Should only belong to one vm assignment at any given time."
                elsif vmassign_results.size == 1
                  xmlinfo << "#{vmguest} already registered to vmhost #{vmassign_results.first.virtual_host.name}\n    - Skipping vm guest assignment registration."
                elsif vmassign_results.empty?
                  xmlinfo << "#{vmguest} not registered to vmhost #{@node.name}.  Registering..."
                  VirtualAssignment.create(
                    :parent_id => @node.id,
                    :child_id => vmnode.id)
                end
              elsif vmresults.size > 1
                xmlinfo << "#{vmguest}: More than 1 nodes found with that name.  Unable to register."
              elsif vmresults.empty?
                xmlinfo << "#{vmguest}: No nodes found with that name.  Unable to register"
              end
            end
          end # if params[:vmguest] == Hash
        end
        params[:node].delete(:virtualmode)
      end
    end

    process_blades(params[:blades]) if params[:blades]
    process_chassis(params[:chassis]) if params[:chassis]
    
    # If the user specified some network interface info then handle that
    if  params[:format] == 'xml'
      # if it's xml request we want to output whether we found a switch port or not.   
      # ideally xmloutput should be used for other steps in this other than just process_network_interfaces,
      # however, we'll start with this for now.
      virtual_guest ? (xmlinfo << process_network_interfaces(:noswitch)) : (xmlinfo << process_network_interfaces)
    else
      virtual_guest ? process_network_interfaces(:noswitch) : process_network_interfaces
    end
    process_storage_controllers
    # If the user specified a rack assignment then handle that
    process_rack_assignment
    # If the user included outlet names apply them now
    if params[:node].include?(:outlet_names)
      @node.update_outlets(params[:node][:outlet_names])
      params[:node].delete(:outlet_names)
    end
    # Process percent_cpu metrics
    process_utilization_metrics if (params["utilization_metric"])
    xmloutput[:info] = xmlinfo.join("\n").to_s 
    # Process volumes
    process_volumes if (params["volumes"])
    process_name_aliases if (params["name_aliases"])

    priorstatus = @node.status
    respond_to do |format|
      if @node.update_attributes(params[:node])
        email_status_update(params,priorstatus)
        flash[:notice] = 'Node was successfully updated.'
        format.html { redirect_to node_url(@node) }
        format.xml  { render :xml => xmloutput.to_xml }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @node.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  def email_status_update(params,priorstatus)
    # Send email notification if change has been made to STATUS
    if ((defined? params[:node][:status_id]) && (!params[:node][:status_id].nil?)) || ((defined? params[:status][:name]) && (!params[:status][:name].nil?))
      mailer_params = {}
      mailer_params[:nodename] = @node.name
      mailer_params[:username] = current_user.name
      mailer_params[:changetype] = 'status'
      mailer_params[:oldvalue] = @node.status.name
      mailer_params[:time] = Time.now
      if (defined? params[:node][:status_id]) && (!params[:node][:status_id].nil?)
        if priorstatus.id != params[:node][:status_id].to_i
          mailer_params[:changevalue] = Status.find(params[:node][:status_id]).name
          logger.info "\n*** Updated Status - sending out email notification 1 ***\n"
          Mailer.deliver_notify_node_change($users_email, mailer_params)
        end
      elsif (defined? params[:status][:name]) && (!params[:status][:name].nil?)
        if priorstatus.name != params[:status][:name]
          logger.info "\n*** Updated Status - sending out email notification 2 ***\n"
          mailer_params[:changevalue] = params[:status][:name]
          Mailer.deliver_notify_node_change($users_email, mailer_params)
        end
      end
    end
  end

  def process_chassis(chassishash)
    return if chassishash['service_tag'].nil? or chassishash['service_tag'].empty?

    # figure out if this node is currently assigned to a chassis
    # by looking to see if  there's an existing outlet that has this node
    # as the consumer, and the produce is a node whose hardware_profile
    # has outlet_type "Blade"
    chassis_outlet = nil
    outlets = Outlet.find_all_by_consumer_id_and_consumer_type(@node.id, 'Node')
    outlets.each do |outlet|
      chassis_outlet = outlet if outlet.producer.hardware_profile.outlet_type == "Blade"
    end if outlets

    # no changes. we're done
    # we're using the chassis' serial tag as the unqueid field of the chassis node
    if chassis_outlet && chassis_outlet.producer.uniqueid == chassishash['service_tag']
      return
    elsif chassis_outlet && chassis_outlet.producer.uniqueid != chassishash['service_tag']
       # Looks like the box is now in a different chassis. Delete the old outlet
      chassis_outlet.destroy
    end

    # Need to create new outlet
    # First find/create the chassis node
    chassis = Node.find_by_uniqueid(chassishash['service_tag'])
    unless chassis
      # outlet_count = 0 means it's not static
      chassis_hdwr_profile = HardwareProfile.find_or_create_by_name_and_outlet_type_and_outlet_count('Generic Chassis', 'Blade', 0)
      status = Status.find_or_create_by_name('available')
      chassis = Node.new(:name => "Chassis-#{chassishash['service_tag']}",
                         :uniqueid => chassishash['service_tag'],
                         :hardware_profile_id => chassis_hdwr_profile.id,
                         :status_id => status.id)
      chassis.save!
    end

    # By default, nventory create slots (outlets) for chassis automatically (named 1 to n)
    chassis_outlets = Outlet.find_all_by_producer_id(chassis.id)
    outlet_exist = false
    # pad with 0 so the outlet shows up in correct order
    slot_num = "%02d" % chassishash['slot_num']
    if chassis_outlets
      chassis_outlets.each do |chassis_outlet|
        if chassis_outlet.name.to_i == chassishash['slot_num'].to_i
          chassis_outlet.update_attributes({:name => slot_num, :consumer_id => @node.id})
          outlet_exist = true
          break
        end
      end 
    end
    unless outlet_exist
      chassis_outlet = Outlet.new(:name => slot_num,
                                  :consumer_id => @node.id, :producer_id => chassis.id)
      chassis_outlet.save! 
    end
  end
  
  def process_blades(bladeshash)
    authoritative = false
    if bladeshash[:authoritative] 
      authoritative = bladeshash[:authoritative]
      bladeshash.delete(:authoritative)
    end
    if authoritative
      foundblades = []
      bladeshash.each_pair do |bayn,attrs|
        bladeoutlet = Outlet.find_or_create_by_producer_id_and_name(@node.id, attrs[:bay])
        foundblades << bladeoutlet if bladeoutlet
      end # bladeshash.each_pair do |bayn,attrs|
      @node.produced_outlets.each{|blade| blade.destroy unless foundblades.include?(blade)}
    end
    bladeshash.each_pair do |bayn,attrs|
      bladeoutlet = Outlet.find_or_create_by_producer_id_and_name(@node.id, attrs[:bay])
      logger.info "\n**** Unable to find or create blade outlet named #{attrs[:bay]} for producer #{@node.name} - Skipping register of blade\n" unless bladeoutlet
      next unless bladeoutlet
      node = Node.find_by_uniqueid(attrs[:uniqueid]) if attrs[:uniqueid] && !attrs[:uniqueid].empty?
      unless node
        results = Node.find(:all, :select => :id, :conditions => ["serial_number like ?","%#{attrs[:serial_number]}%"])
        node = results[0] if results.size == 1
      end
      unless node
        results = Node.find(:all, :select => 'nodes.id', :include => {:network_interfaces => {:ip_addresses => {} } }, :conditions => ["ip_addresses.address like ?","%#{attrs[:ip_address]}%"]) unless node
        node = results[0] if results.size == 1
      end
      if node
        if !bladeoutlet.consumer || (bladeoutlet.consumer_id != node.id)
          logger.info "\n**** UPDATING OUTLET: #{bladeoutlet.id} => consumer => #{node.id}" 
          bladeoutlet.consumer = nil and bladeoutlet.save
          bladeoutlet.update_attributes({:consumer_id => node.id, :consumer_type => 'Node'})
        end # if bladeoutlet.node.id != node.id
      else
        logger.info "\n**** Unable to find outlet consumer named uniqueid #{attrs[:uniqueid]} nor serial number #{attrs[:serial_number]} nor ip_address #{attrs[:ip_address]}"
        if bladeoutlet.consumer
          logger.info "    - Removing consumer #{bladeoutlet.consumer.id} from outlet #{bladeoutlet.id}"
           bladeoutlet.consumer = nil
           bladeoutlet.save
        end
      end # unless node
    end # bladeshash.each_pair do |bayn,attrs|
  end

  # DELETE /nodes/1
  # DELETE /nodes/1.xml
  def destroy
    @node = Node.find(params[:id])
    begin
      @node.destroy
    rescue Exception => destroy_error
      respond_to do |format|
        flash[:error] = destroy_error.message
        format.html { redirect_to node_url(@node) and return}
        format.xml  { head :error } # FIXME?
      end
    end
    
    # Success!
    respond_to do |format|
      format.html { redirect_to nodes_url }
      format.xml  { head :ok }
    end
  end
  
  # GET /nodes/1/version_history
  def version_history
    @node = Node.find(params[:id])
    render :action => "version_table", :layout => false
  end
  
  # GET /nodes/1/available_outlet_consumers
  def available_outlet_consumers
    # @node = Node.find(params[:id])
    @nodes = Node.find(:all, :order => 'name')
    render :action => "available_outlet_consumers", :layout => false
  end
  
  # GET /nodes/field_names
  def field_names
    super(Node)
  end

  # GET /nodes/search
  def search
    @node = Node.find(:first)
    render :action => 'search'
  end
  
  def find_or_create_operating_system
    logger.info "User did not include an OS id, searching for one"
    # The to_s converts nil to "", which matches what the web UI does
    # if you leave a field blank.
    os = OperatingSystem.find_by_name(params[:operating_system][:name].to_s)
    if os.nil?
      os = OperatingSystem.find_by_vendor_and_variant_and_version_number_and_architecture(
        params[:operating_system][:vendor].to_s,
        params[:operating_system][:variant].to_s,
        params[:operating_system][:version_number].to_s,
        params[:operating_system][:architecture].to_s)
        if os.nil?
        logger.info "No existing OS found, creating one"
        os = OperatingSystem.create(
          :vendor         => params[:operating_system][:vendor].to_s,
          :variant        => params[:operating_system][:variant].to_s,
          :version_number => params[:operating_system][:version_number].to_s,
          :architecture   => params[:operating_system][:architecture].to_s,
          :name           => "#{params[:operating_system][:vendor]} #{params[:operating_system][:variant]} #{params[:operating_system][:version_number]} #{params[:operating_system][:architecture]}".strip)
      end
    end
    return os
  end
  private :find_or_create_operating_system
  
  def process_utilization_metrics
    metrics = %w(percent_cpu login_count)
    metrics.each do |metric_name|
      if (defined?(params['utilization_metric'][metric_name]['value']))
        unless (params['utilization_metric'][metric_name]['value'] =~ /\D/)
          utilization_metric_name = UtilizationMetricName.find_by_name(metric_name)
          UtilizationMetric.create({:utilization_metric_name => utilization_metric_name,
              :node => @node, :value => params['utilization_metric'][metric_name]['value'].to_i})
        end
      end
    end
  end

  def find_or_create_hardware_profile
    hwprof = HardwareProfile.find_by_name(params[:hardware_profile][:name].to_s)
    if hwprof.nil?
      hwprof = HardwareProfile.find_by_manufacturer_and_model(
        params[:hardware_profile][:manufacturer].to_s,
        params[:hardware_profile][:model].to_s)
      if hwprof.nil?
        hwprof = HardwareProfile.create(
          :manufacturer => params[:hardware_profile][:manufacturer].to_s,
          :model        => params[:hardware_profile][:model].to_s,
          :name         => "#{params[:hardware_profile][:manufacturer]} #{params[:hardware_profile][:model]}".strip)
      end
    end
    return hwprof
  end
  private :find_or_create_hardware_profile

  def find_vm_host
    info = ["\n"]
    # If the user specified some network interface info then handle that
    if params.include?(:network_interfaces)
      nichashes = []
      if params[:network_interfaces].kind_of?(Hash)
        # Pull out the authoritative flag if the user specified it
        nichashes = params[:network_interfaces].values
      elsif params[:network_interfaces].kind_of?(Array)
        nichashes = params[:network_interfaces]
      end
      vmhost = {}
      nichashes.each do |nichash|
        if nichash.include?("switch")
          vmhost[:switch] = nichash["switch"]
          vmhost[:swport] = nichash["port"]
        end
      end
      if (vmhost[:switch] && vmhost[:swport])
        # find the switch by name
        sw_results = Node.find(:all,:conditions => ["name like ?", "%#{vmhost[:switch]}%"])
        if sw_results.size == 1
          sw_object = sw_results.first
        else
          info << "The switch name (#{vmhost[:switch]}) provided by cdpr resulted in more or less than 1 match against nventory\n"
          return nil
        end
        # now find the switch port for this switch
        port_results = Outlet.find(:all,:conditions => ["producer_id = ? and name like ?", sw_object.id, "Gi#{vmhost[:swport]}"])
        if port_results.size == 1
          port_obj = port_results.first
        else
          info << "The port name (#{vmhost[:swport]}) provided by cdpr resulted in more or less than 1 match against nventory\n"
          return nil
        end
        # now that we have the port obj, we can determine who the node attached to it is
        vmhost[:node] = port_obj.consumer.node unless port_obj.consumer.nil?
      end
      return vmhost[:node] unless vmhost[:node].nil? 
    else
      return nil
    end
  end

  def process_name_aliases
    if defined?(params["name_aliases"])
      reg_aliases = params["name_aliases"]["name"].split(',')
      return if reg_aliases.nil?
      node_aliases = @node.name_aliases.collect{|na| na.name}
      reg_aliases.each do |na|
        unless node_aliases.include?(na)
          new_alias = NameAlias.create({:source_type => 'Node', :source => @node, :name => na})
        end
      end
    end
  end

  def process_volumes
    if defined?(params["volumes"]) 

      ## MOUNTED VOLUMES ##

      all_mounted = params["volumes"]["mounted"]
      unless all_mounted.nil? || all_mounted.empty?
        all_mounted.keys.each do |mounted_vol|
          # First we need to search if the volume already exists, based on the volume name and the server name.  
          volume_server_name = all_mounted[mounted_vol]["volume_server"]
          logger.info "Processing volume #{mounted_vol} hosted on server #{volume_server_name}..."
          # Search server by name, if more than 1 match, then we cannot process
          results = Node.find(:all, :conditions => ["nodes.name like ? OR name_aliases.name like ?", "%#{volume_server_name}%", "%#{volume_server_name}%"], :include => {:name_aliases => {}})
  	if results.size == 1
            volume_server = results.first
            volume_name = all_mounted[mounted_vol]["volume"]
            volume_type = all_mounted[mounted_vol]["type"]
            volume_config = all_mounted[mounted_vol]["config"]
            # now try to find the volume
            result = Volume.find(:all, :conditions => ["name = ? and volume_server_id = ?", volume_name, volume_server.id])
            if result.size == 1
              # check if volume type is the same else update it
              volume = result.first
              unless volume.volume_type.to_s == volume_type
                volume.volume_type = volume_type
                volume.save
              end # unless volume.volume_tpe.to_s
            elsif result.size == 0
              # Volume doesn't exist but we have all the data, so create the volume w/ the server's info
              volume = Volume.new
              volume.volume_server = volume_server
              volume.name = volume_name
              volume.volume_type = volume_type
              volume.save
            else
              logger.info "Found more than 1 volume results for #{mounted_vol} on #{volume_server_name}:#{volume_type}"
              next
            end # if result == 1
            # now that we have the volume object, we want to find or create a volume<=>node assignment
            vna_result = VolumeNodeAssignment.find(:all, :conditions => ["node_id = ? and volume_id = ? and mount = ?", @node.id, volume.id, mounted_vol] )
            if  vna_result.size == 0 
              # Didn't find, thus create
              vna = VolumeNodeAssignment.new
              vna.node = @node
              vna.volume = volume
              vna.mount = mounted_vol
              vna.configf = volume_config
              vna.save
            else
              logger.info "\n\n\nFound 1 or more volume_node_assignments for #{@node.name}:#{mounted_vol} from #{volume_server_name}, skipping\n\n\n"
              next
            end
          else
            logger.info "  - More than 1 match found for #{volume_server_name}"
            next
          end # unless results.size == 1
        end # all_mounted.keys.each
      end # unless (all_mounted.nil? ||

      ## SERVED VOLUMES ##
      all_served = params["volumes"]["served"]
      unless all_served.nil? || all_served.empty?
        all_served.keys.each do |served_vol|
          volume_config = all_served[served_vol]["config"] 
          volume_type = all_served[served_vol]["type"] 
          result = Volume.find(:all, :conditions => ["volume_server_id = ? and volume_type = ? and name = ?",@node.id, volume_type, served_vol ])
          if result.size == 0
            volume = Volume.new
            volume.name = served_vol
            volume.volume_server = @node
            volume.configf = volume_config
            volume.volume_type = volume_type
            volume.save
          elsif result.size == 1
            logger.info "Volume already exists.  Will update if necessary.."
            volume = result.first
            volume.volume_type = volume_type unless (volume.volume_type == volume_type)
          else
            logger.info "More than one volume found.  Skipping.."
            next
          end # if results.size == 0
        end # all_served.keys.each
      end # unless (all_served.nil? ||
    end # if defined?(params["volumes"])
  end

  def process_network_interfaces(flag='')
    info = []
    # If the user specified some network interface info then handle that
    if params.include?(:network_interfaces)
      logger.info "User included network interface info, handling it"

      authoritative = false
      nichashes = []
      if params[:network_interfaces].kind_of?(Hash)
        # Pull out the authoritative flag if the user specified it
        if params[:network_interfaces].include?(:authoritative)
          authoritative = params[:network_interfaces][:authoritative]
          params[:network_interfaces].delete(:authoritative)
        end
        nichashes = params[:network_interfaces].values
      elsif params[:network_interfaces].kind_of?(Array)
        nichashes = params[:network_interfaces]
      end
      
      nichashes.each do |nichash|

        # Temporarily remove any IP data from the Network Interfacedata so as not
        # to confuse the Network Interface model
        iphashes = []
        if nichash.include?(:ip_addresses)
          logger.info "User included IP info, saving it"
          if nichash[:ip_addresses].kind_of?(Hash)
            iphashes = nichash[:ip_addresses].values
          elsif nichash[:ip_addresses].kind_of?(Array)
            iphashes = nichash[:ip_addresses]
          end
          nichash.delete(:ip_addresses)
        end

        # Remove switch info for processing outside the nic model
        # and then try to see if we can find the switchand port to correspond exactly
        if ( nichash[:interface_type] && nichash[:interface_type] == "Ethernet" )
            switch = {}
            if nichash.include?(:switch)
              switch[:name] = nichash[:switch]
              nichash.delete(:switch)
            end
            if nichash.include?(:port)
              switch[:port] = nichash[:port]
              nichash.delete(:port)
            end
            if nichash.include?(:portspeed)
              switch[:portspeed] = nichash[:portspeed]
              nichash.delete(:portspeed)
            end
            if (switch[:port] && switch[:name])
              sw_results = Node.find(:all,:conditions => ["name like ?", "%#{switch[:name]}%"])
              if sw_results.size == 1
                # check if a switch
                if !sw_results.first.hardware_profile.outlet_type.nil? && sw_results.first.hardware_profile.outlet_type.match(/Network/)
                  # found the switch , not what?
                  sw_object = sw_results.first
                  # look for the association of switch(node#object) and port(Outlet#id)
                  port_results = Outlet.find(:all,:conditions => ["producer_id = ? and name like ?", sw_object.id, "Gi#{switch[:port]}"])
                  if port_results.size == 1
                    port = port_results.first
                  elsif port_results.size > 1
                    # return error that the switch has MORE than ONE port results with that name
                    info << "The port name (#{switch[:port]}) provided by cdpr resulted in more than 1 match against nventory"
                  else
                    info << "The port name (#{switch[:port]}) wasn't found for the switch name (#{switch[:name]}) provided"
                  end
                else 
                  # return error that found the name but isn't a switch hardware-profile
                  info << "Switch name (#{switch[:name]}) provided by cdpr isn't registered in nventory as a Network type hardware"
                end
              elsif sw_results.size == 0
                # send error back that didn't find the switch
                info << "Found no switch name matches for switch name (#{switch[:name]}) provided by cdpr"
              elsif sw_results.size > 1 
                # send error back that it found more than one switch with that name
                info << "Found more than 1 switch name matches for switch name (#{switch[:name]}) provided by cdpr"
              end
            else
              info << "#{nichash[:name]}: Not enough switch data provided by cdpr to register system's switch port against nventory"
            end
            # try to assign nic to the correct switch port if we've been able to determine one 
            if (port && (flag != :noswitch))
              nichash[:switch_port] = port
              info << "#{nichash[:name]}: Registered switch port successfully (to #{port.producer.name} #{port.name})"
            else
              info << "#{nichash[:name]}: Skipped switch port registration"
            end
        end # if interface_type == "Ethernet"

        # Create/update the Network Interface
        logger.info "Search for network interface #{nichash[:name]}"
        nic = @node.network_interfaces.find_by_name(nichash[:name])
        if nic.nil?
          logger.info "Network interface #{nichash[:name]} doesn't exist, creating it" + nichash.to_yaml
          nic = @node.network_interfaces.create(nichash)
        else
          logger.info "User #{nichash[:name]} already exists, updating it" + nichash.to_yaml
          nic.update_attributes(nichash)
        end

        # Stick the IP data back into the hash for later use
        nichash[:ip_addresses] = iphashes

        # And process the IP data
        iphashes.each do |iphash|
          # Temporarily remove any PORT data from the IpAddress so as not to confuse its model
          porthashes = []
          if iphash.include?(:network_ports)
            logger.info "User included Network Port info, saving it"
            if iphash[:network_ports].kind_of?(Hash)
              porthashes = iphash[:network_ports].values
            elsif iphash[:network_ports].kind_of?(Array)
              porthashes = iphash[:network_ports]
            end
            iphash.delete(:network_ports)
          end

          logger.info "Search for IP #{iphash[:address]}"
          ip = nic.ip_addresses.find_by_address(iphash[:address])
          if ip.nil?
            logger.info "IP #{iphash[:address]} doesn't exist, creating it" + iphash.to_yaml
            ip = nic.ip_addresses.create(iphash)
            # now process the ports info for each ip_address
            process_network_ports(ip, porthashes) unless porthashes.empty?
          else
            logger.info "IP #{iphash[:address]} exists, updating it" + iphash.to_yaml
            ip.update_attributes(iphash)
            # now process the ports info for each ip_address
            process_network_ports(ip, porthashes) unless porthashes.empty?
          end
        end # iphashes.each
      end # nichashes.each
    
      # If the client indicated that they were sending us an authoritative
      # set of Network Interface info (for example, a client in registration mode) then
      # remove any Network Interface and IPs stored in the database which the client
      # didn't include in the info it sent
      if authoritative
        nic_names_from_client = []
        nichashes.each { |nichash| nic_names_from_client.push(nichash[:name]) }
        @node.network_interfaces.each do |nic|
          if !nic_names_from_client.include?(nic.name)
            nic.destroy
          else
            nichash = nil
            nichashes.each { |nh| nichash = nh if nh[:name] == nic.name }
            ips_from_client = []
            nichash[:ip_addresses].each { |iphash| ips_from_client.push(iphash[:address]) }
            nic.ip_addresses.each do |ip|
              if !ips_from_client.include?(ip.address)
                ip.destroy
              end
            end
          end
        end
      end
      
      # process and RETURN the info msgs into one big string 
      output = String.new
      info.each { |msg| output << msg + "\n" }
      output

    end # if params.include?(:network_interfaces)
  end
  private :process_network_interfaces

  def process_network_ports(ip, porthashes)
    logger.info "\n\n*********** PROCESSING NETWORK PORTS ***************"
    logger.info "IP: #{ip.address}\n" + porthashes.to_yaml + "\n\n"
    
    porthashes.each do |porthash|
      logger.info "Search for PORT: #{porthash[:number]}/#{porthash[:protocol]}"
      port = NetworkPort.find_or_create_by_number_and_protocol(porthash[:number].to_i,porthash[:protocol])
      ipnpa = IpAddressNetworkPortAssignment.find_or_create_by_ip_address_id_and_network_port_id(ip.id,port.id)
      if ipnpa
        appname = nil
        # we want to append to the :app field instead of overwriting unless that appname already is listed
        if ipnpa.apps && ipnpa.apps =~ /\w/
          if ipnpa.apps =~ /\b#{porthash[:apps]}\b/
            appname = ipnpa.apps.gsub(/\s/,'')
          else
            appname = [ipnpa.apps.gsub(/\s/,''), porthash[:apps]].join(',')
          end
        else
          appname = porthash[:apps]
        end
        ipnpa.update_attributes(:apps => appname) unless appname.nil? || ipnpa.apps == appname
      end  # if ipnpa
      logger.info "** NetworkPortIpAddressAssignment RESULT (ID): #{ipnpa.id}"
    end
  end
  private :process_network_ports
  
  def process_storage_controllers(flag='')
    info = []
    # If the user specified some network interface info then handle that
    if params.include?(:storage_controllers)
      logger.info "User included storage controller info, handling it"

      authoritative = false
      schashes = []
      if params[:storage_controllers].kind_of?(Hash)
        # Pull out the authoritative flag if the user specified it
        if params[:storage_controllers].include?(:authoritative)
          authoritative = params[:storage_controllers][:authoritative]
          params[:storage_controllers].delete(:authoritative)
        end
        schashes = params[:storage_controllers].values
      elsif params[:storage_controllers].kind_of?(Array)
        schashes = params[:storage_controllers]
      end
      
      schashes.each do |schash|
        # remove drives from storage controller hash to be processed after
        drvhashes = []
        if schash["drives"]
          drvhashes = schash["drives"].values
          schash.delete("drives")
        end
        # only allow legitimate fields of the model
        sc_allowedf = {}
        StorageController.column_names.each {|cn| sc_allowedf[cn] = 1 unless cn == 'id' }
        schash.keys.each{ |sckey| schash.delete(sckey) unless sc_allowedf[sckey] }
        # Create/update the Storage Controller
        logger.info "Search for Storage Controller #{schash[:name]}"
        sc = @node.storage_controllers.find_by_name(schash[:name])
        if sc.nil?
          logger.info "Storage Controller #{schash[:name]} doesn't exist, creating it" + schash.to_yaml
          sc = @node.storage_controllers.create(schash)
        else
          logger.info "User #{schash[:name]} already exists, updating it" + schash.to_yaml
          sc.update_attributes(schash)
        end
        # now revisit processing drives
        drvhashes.each do |drvhash|
          # remove volumes for processing later
          vlmhashes = []
          if drvhash["volumes"] 
            vlmhashes = drvhash["volumes"].values
            drvhash.delete("volumes")
          end 
          # only allow legitimate fields of the model
          drv_allowedf = {}
          Drive.column_names.each {|cn| drv_allowedf[cn] = 1 unless cn == 'id' }
          drvhash.keys.each{ |drvkey| drvhash.delete(drvkey) unless drv_allowedf[drvkey] }
          # Create/update the drive
          logger.info "Search for Drive #{drvhash[:name]}"
          drv = sc.drives.find_by_name(drvhash[:name])
          if drv.nil?
            logger.info "Drive #{drvhash[:name]} doesn't exist, creating it" + drvhash.to_yaml
            drv = sc.drives.create(drvhash)
          else
            logger.info "Drive #{drvhash[:name]} already exists, updating it" + drvhash.to_yaml
            drv.update_attributes(drvhash)
          end # if drv.nil?
          # now revisit processing volumes
          vlmhashes.each do |vlmhash|
            # Create/update the drive
            logger.info "Search for Volume #{vlmhash[:name]}"
            vlm = drv.volumes.find_by_name(vlmhash[:name])
            unless vlmhash[:volume_type]
              Volume.volume_types.each do |vt|
                vlmhash[:volume_type] = vt if vlmhash[:description] =~ /#{vt}/i
              end
            end
            # only allow legitimate fields of the model
            vlm_allowedf = {}
            Volume.column_names.each {|cn| vlm_allowedf[cn] = 1 unless cn == 'id' }
            vlmhash.keys.each{ |vlmkey| vlmhash.delete(vlmkey) unless vlm_allowedf[vlmkey] }
            if vlm.nil?
              logger.info "Volume #{vlmhash[:name]} doesn't exist, creating it" + vlmhash.to_yaml
              vlm = drv.volumes.create(vlmhash)
            else
              logger.info "Volume #{vlmhash[:name]} already exists, updating it" + vlmhash.to_yaml
              vlm.update_attributes(vlmhash)
              unless drv.volumes.include?(vlm)
                drv.volumes << vlm
                drv.save
              end # unless drv.volumes.include?(vlm)
            end # if vlm.nil?
          end # vlmhashes.each do
        end # drvhashes.each do 
      end # schashes.each
    
      # If the client indicated that they were sending us an authoritative
      # set of Storage Controller info (for example, a client in registration mode) then
      # remove any Storage Controllers and volumes/disks stored in the database which the client
      # didn't include in the info it sent
      if authoritative
        sc_names_from_client = []
        schashes.each { |schash| sc_names_from_client.push(schash[:name]) }
        @node.storage_controllers.each{ |sc| sc.destroy unless sc_names_from_client.include?(sc.name) }
      end
      
      # process and RETURN the info msgs into one big string 
      output = String.new
      info.each { |msg| output << msg + "\n" }
      output

    end # if params.include?(:storage_controllers)
  end
  private :process_storage_controllers

  def graph_node_groups
    image_type = MyConfig.visualization.images.mtype
    @node = Node.find(params[:id])
    @graphobjs = {}
    @graph = GraphViz::new( "G", "output" => "png" )
    @dots = {}
    @all_node_groups = @node.node_groups
    @real_node_groups = @node.real_node_groups
    @node.real_node_groups.each do |ng|
      # Add this node's parent ngs as services
      @graphobjs[ng.name.gsub(/-/,'')] = @graph.add_node(ng.name.gsub(/-/,''), :label => "#{ng.name}", :shape => 'rectangle', :color => "yellow", :style => "filled")
      # walk the ng's parents service tree
      dot_parent_node_groups(ng)
      # walk the ng's children service tree 
      dot_child_node_groups(ng)
    end
    ## Write the function to add all the dot points from the hash
    @dots.each_pair do |parent,children|
      children.uniq.each do |child|
        @graph.add_edge( @graphobjs[parent],@graphobjs[child] )
      end
    end
    @graph.output( :output => image_type,:file => "public/#{MyConfig.visualization.images.dir}/#{@node.name}_nodegroups.#{image_type}" )
    respond_to do |format|
      format.html # graph_node_groups.html.erb
    end
  end

  def reset_ngs
    @node = Node.find(params[:id])
    return unless filter_perms(@auth,@node,['updater'])
    @node.real_node_groups.each do |rng|
      return unless filter_perms(@auth,rng,['updater'])
    end
    @node.reset_node_groups
    respond_to do |format|
      format.js {
        render(:update) { |page|
          page.replace_html 'node_group_node_assignments', :partial => 'nodes/node_group_assignments', :locals => { :node => @node }
        }
      }
    end
  end

  def dot_child_node_groups(ng)
    ng.child_groups.each do |child_group|
      if (@all_node_groups.include?(child_group) && !@real_node_groups.include?(child_group))
        # Virtual Node Groups should be colored purple
        @graphobjs[child_group.name.gsub(/[-.]/,'')] = @graph.add_node(child_group.name.gsub(/[-.]/,''), :label => "#{child_group.name}", :shape => 'rectangle', :color => 'purple', :style => 'filled')
      else
        @graphobjs[child_group.name.gsub(/[-.]/,'')] = @graph.add_node(child_group.name.gsub(/[-.]/,''), :label => "#{child_group.name}", :shape => 'rectangle')
      end
      @dots[ng.name.gsub(/[-.]/,'')] = [] unless @dots[ng.name.gsub(/[-.]/,'')]
      @dots[ng.name.gsub(/[-.]/,'')] << child_group.name.gsub(/[-.]/,'')
      unless child_group.child_groups.empty?
        dot_child_node_groups(child_group)
      end
    end
  end
  private :dot_child_node_groups

  def dot_parent_node_groups(ng)
    ng.parent_groups.each do |parent_group|
      if (@all_node_groups.include?(parent_group) && !@real_node_groups.include?(parent_group))
        @graphobjs[parent_group.name.gsub(/[-.]/,'')] = @graph.add_node(parent_group.name.gsub(/[-.]/,''), :label => "#{parent_group.name}", :shape => 'rectangle', :color => 'purple', :style => 'filled')
      else
        @graphobjs[parent_group.name.gsub(/[-.]/,'')] = @graph.add_node(parent_group.name.gsub(/[-.]/,''), :label => "#{parent_group.name}", :shape => 'rectangle')
      end
      @dots[parent_group.name.gsub(/[-.]/,'')] = [] unless @dots[parent_group.name.gsub(/[-.]/,'')]
      @dots[parent_group.name.gsub(/[-.]/,'')] << ng.name.gsub(/[-.]/,'')
      unless parent_group.parent_groups.empty?
        dot_parent_node_groups(parent_group)
      end
    end
  end
  private :dot_parent_node_groups

  def graph_services
    @node = Node.find(params[:id])
    @graphobjs = {}
    @graph = GraphViz::new( "G", "output" => "png" )
    @dots = {}
    @node.real_node_groups.each do |ng|
      # Add this node's parent ngs as services
      @graphobjs[ng.name.gsub(/-/,'')] = @graph.add_node(ng.name.gsub(/-/,''), :label => "#{ng.name}", :shape => 'rectangle', :color => "yellow", :style => "filled")
      # walk the ng's parents service tree
      dot_parent_services(ng)
      # walk the ng's children service tree 
      dot_child_services(ng)
    end
    ## Write the function to add all the dot points from the hash
    @dots.each_pair do |parent,children|
      children.uniq.each do |child|
        @graph.add_edge( @graphobjs[parent],@graphobjs[child] )
      end
    end
    @graph.output( :output => 'gif',:file => "public/images/#{@node.name}_servicetree.gif" )
    respond_to do |format|
      format.html # graph_services.html.erb
    end
  end

  def dot_child_services(rng)
    ng = Service.find(rng.id)
    ng.child_services.each do |child_service|
      @graphobjs[child_service.name.gsub(/[-.]/,'')] = @graph.add_node(child_service.name.gsub(/[-.]/,''), :label => "#{child_service.name}", :shape => 'rectangle')
      @dots[ng.name.gsub(/[-.]/,'')] = [] unless @dots[ng.name.gsub(/[-.]/,'')]
      @dots[ng.name.gsub(/[-.]/,'')] << child_service.name.gsub(/[-.]/,'')
      unless child_service.child_services.empty?
        dot_child_services(child_service)
      end
    end
  end
  private :dot_child_services

  def dot_parent_services(rng)
    ng = Service.find(rng.id)
    ng.parent_services.each do |parent_service|
      @graphobjs[parent_service.name.gsub(/[-.]/,'')] = @graph.add_node(parent_service.name.gsub(/[-.]/,''), :label => "#{parent_service.name}", :shape => 'rectangle')
      @dots[parent_service.name.gsub(/[-.]/,'')] = [] unless @dots[parent_service.name.gsub(/[-.]/,'')]
      @dots[parent_service.name.gsub(/[-.]/,'')] << ng.name.gsub(/[-.]/,'')
      unless parent_service.parent_services.empty?
        dot_parent_services(parent_service)
      end
    end
  end
  private :dot_parent_services

  def process_rack_assignment
    # If the user specified a rack assignment then handle that
    if params.include?(:node_rack)
      logger.info "User included rack assignment, handling it"
      existing = NodeRackNodeAssignment.find_by_node_id(@node.id)
      if !existing.nil?
        # Check to see if the existing assignment is correct
        node_rack = nil
        if !params[:node_rack][:id].blank?
          if params[:node_rack][:id] != existing.rack.id
            node_rack = NodeRack.find(params[:node_rack][:id])
          end
        elsif !params[:node_rack][:name].blank?
          if params[:node_rack][:name] != existing.node_rack.name
            node_rack = NodeRack.find_by_name(params[:node_rack][:name])
          end
        end
        if !node_rack.nil?
          existing.update_attributes(:node_rack => node_rack, :assigned_at => Time.now)
        end
      else
        # Create a new assignment
        node_rack = nil
        if !params[:node_rack][:id].blank?
          node_rack = NodeRack.find(params[:node_rack][:id])
        elsif !params[:node_rack][:name].blank?
          node_rack = NodeRack.find_by_name(params[:node_rack][:name])
        end
        if !node_rack.nil?
          NodeRackNodeAssignment.create(:node_rack => node_rack, :node => @node)
        end
      end
    end
  end
  private :process_rack_assignment

  def cpu_percent_chart_method
    @node = Node.find(params[:id])
    data = {}
    data[:days] = []
    data[:values] = []

    # Create datapoints for the past 12 months and keep them in array so that their order is retained
    counter = 10
    while counter > 0 
      day = counter
      values = UtilizationMetric.find(
          :all, :select => :value, :joins => {:utilization_metric_name => {}, :node => {}},
          :conditions => ["nodes.id = ? and assigned_at like ? and utilization_metric_names.name = ?", @node.id, "%#{day.days.ago.strftime("%Y-%m-%d")}%", 'percent_cpu'])
      # each day should only have 1 value, if not then create an average
      if values.size == 0 
        counter -=1
        next
      elsif values.size == 1
        value = values.first.value
      else
        value = values.collect{|a| a.value.to_i }.sum / values.size
      end 
      data[:days] << day.days.ago.strftime("%m/%d")
      data[:values] << value.to_i
      counter -= 1
    end 
    PP.pp data
    # Create Graph
    title = Title.new("#{@node.name.gsub(/\..*/,'')} CPU% Utilization")
    title.set_style('{font-size: 20px; color: #778877}')
    line = Line.new
    line.text = "%" 
    line.set_values(data[:values])
    y = YAxis.new
    y.set_range(0,100,10)
    x = XAxis.new
    x.set_labels(data[:days])

    chart = OpenFlashChart.new
    chart.set_title(title)
    chart.add_element(line)
    chart.x_axis = x 
    chart.y_axis = y 

    return chart
  end 

  def get_volume_nodes
    @nodes = Node.find(:all, :order => :name).collect{|node| [node.name,node.id]}
    render :partial => 'show_volume_nodes'
  end

  def get_nics
    if params[:id] && params[:partial]
      @node = Node.find(params[:id])
      render :partial => params[:partial], :locals => { :node => @node }
    else
      render :text => ''
    end
  end

end
