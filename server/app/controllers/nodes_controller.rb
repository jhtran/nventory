class NodesController < ApplicationController
  # GET /nodes
  # GET /nodes.xml
  def index
    # Turns on csv export form on
    @csvon = "true"
    params[:csv] = true
    # The default display index_row columns
    default_includes = [:operating_system, :hardware_profile, :node_groups, :status] 
    special_joins = {
      'preferred_operating_system' =>
        'LEFT OUTER JOIN operating_systems AS preferred_operating_systems ON nodes.preferred_operating_system_id = preferred_operating_systems.id'
    }
    
    ## BUILD MASTER HASH WITH ALL SUB-PARAMS ##
    allparams = {}
    allparams[:mainmodel] = Node
    allparams[:webparams] = params
    allparams[:default_includes] = default_includes
    allparams[:special_joins] = special_joins
    
    results = SearchController.new.search(allparams)
    flash[:error] = results[:errors].join('<br />') unless results[:errors].empty?
    includes = results[:includes]
    @objects = results[:search_results]
    
    # search results should contain csvobj which contains all the params for building and put it in session.  View will launch csv controller to call on that session
    if @csvon == "true"
      results[:csvobj]['def_attr_names'] = %w(name operating_system hardware_profile node_groups status)
      session[:csvobj] = results[:csvobj] 
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml do 
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
    includes = process_includes(Node, params[:include])
    @node = Node.find(params[:id], :include => includes)
    @parent_services = @node.node_groups.collect { |ng| ng.parent_services }.flatten
    @child_services = @node.node_groups.collect { |ng| ng.child_services }.flatten

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @node.to_xml(:include => convert_includes(includes),
                                                :dasherize => false) }
    end
  end

  # GET /nodes/new
  def new
    @node = Node.new
    respond_to do |format|
      format.html # show.html.erb
      format.js  { render :action => "inline_new", :layout => false }
    end
  end

  # GET /nodes/1/edit
  def edit
    @node = Node.find(params[:id])
  end

  # POST /nodes
  # POST /nodes.xml
  def create

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
        # If the user specified a rack assignment then handle that
        process_rack_assignment
        # If the user included outlet names apply them now
        if outlet_names
          @node.update_outlets(outlet_names)
        end
        
        flash[:notice] = 'Node was successfully created.'
        format.html { redirect_to node_url(@node) }
        format.js { 
          render(:update) { |page| 
            
            # Depending on where the Ajax node creation comes from
            # we do something slightly different.
            if request.env["HTTP_REFERER"].include? "racks"
              page.replace_html 'create_node_assignment', :partial => 'shared/create_assignment', :locals => { :from => 'rack', :to => 'node' }
              page['rack_node_assignment_node_id'].value = @node.id
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
    xmloutput = {}
    xmlinfo = [""]
    @node = Node.find(params[:id])

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
                VirtualAssignment.create(
                  :parent_id => vmhost.id,
                  :child_id => @node.id)
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
          vmguests = params[:node][:vmguests].split(',')
          # clear this out of hash or will try to register a non-existing table column
          params[:node].delete(:vmguests)
          # try to find each node if exists in nventory, if does then see if virtual assign exists to this vm host, if not create it
          vmguests.each do |vmguest|
            vmresults = Node.find(:all,:conditions => ["name like ?","#{vmguest}%"])
            if vmresults.size == 1
              vmnode = vmresults.first
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
            elsif vmresults > 1
              xmlinfo << "#{vmguest}: More than 1 nodes found with that name.  Unable to register."
            elsif vmresults.empty?
              xmlinfo << "#{vmguest}: No nodes found with that name.  Unable to register"
            end
          end
        end
        params[:node].delete(:virtualmode)
      end
    end
    
    # If the user specified some network interface info then handle that
    if  params[:format] == 'xml'
      # if it's xml request we want to output whether we found a switch port or not.   
      # ideally xmloutput should be used for other steps in this other than just process_network_interfaces,
      # however, we'll start with this for now.
      virtual_guest ? (xmlinfo << process_network_interfaces(:noswitch)) : (xmlinfo << process_network_interfaces)
    else
      virtual_guest ? process_network_interfaces(:noswitch) : process_network_interfaces
    end
    # If the user specified a rack assignment then handle that
    process_rack_assignment
    # If the user included outlet names apply them now
    if params[:node].include?(:outlet_names)
      @node.update_outlets(params[:node][:outlet_names])
      params[:node].delete(:outlet_names)
    end

    xmloutput[:info] = xmlinfo.join("\n").to_s 

    respond_to do |format|
      if @node.update_attributes(params[:node])
        flash[:notice] = 'Node was successfully updated.'
        format.html { redirect_to node_url(@node) }
        format.xml  { render :xml => xmloutput.to_xml }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @node.errors.to_xml, :status => :unprocessable_entity }
      end
    end
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
        vmhost[:node] = port_obj.consumer.node
      end
      return vmhost[:node] unless vmhost[:node].nil? 
    else
      return nil
    end
  end
  
  def process_network_interfaces(flag='')
    info = []
    # If the user specified some network interface info then handle that
    if params.include?(:network_interfaces)
      logger.info "User included NIC info, handling it"

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

        # Temporarily remove any IP data from the NIC data so as not
        # to confuse the NIC model
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

        # Create/update the NIC
        logger.info "Search for NIC #{nichash[:name]}"
        nic = @node.network_interfaces.find_by_name(nichash[:name])
        if nic.nil?
          logger.info "NIC #{nichash[:name]} doesn't exist, creating it" + nichash.to_yaml
          nic = @node.network_interfaces.create(nichash)
        else
          logger.info "User #{nichash[:name]} already exists, updating it" + nichash.to_yaml
          nic.update_attributes(nichash)
        end

        # Stick the IP data back into the hash for later use
        nichash[:ip_addresses] = iphashes

        # And process the IP data
        iphashes.each do |iphash|
          logger.info "Search for IP #{iphash[:address]}"
          ip = nic.ip_addresses.find_by_address(iphash[:address])
          if ip.nil?
            logger.info "IP #{iphash[:address]} doesn't exist, creating it" + iphash.to_yaml
            nic.ip_addresses.create(iphash)
          else
            logger.info "IP #{iphash[:address]} exists, updating it" + iphash.to_yaml
            ip.update_attributes(iphash)
          end
        end # iphashes.each
      end # nichashes.each
    
      # If the client indicated that they were sending us an authoritative
      # set of NIC info (for example, a client in registration mode) then
      # remove any NICs and IPs stored in the database which the client
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

  def graph_node_groups
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
    @graph.output( :output => 'gif',:file => "public/images/#{@node.name}_nodegroups.gif" )
    respond_to do |format|
      format.html # graph_node_groups.html.erb
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

  def dot_child_services(ng)
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

  def dot_parent_services(ng)
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
    if params.include?(:rack)
      logger.info "User included rack assignment, handling it"
      existing = RackNodeAssignment.find_by_node_id(@node.id)
      if !existing.nil?
        # Check to see if the existing assignment is correct
        rack = nil
        if !params[:rack][:id].blank?
          if params[:rack][:id] != existing.rack.id
            rack = Rack.find(params[:rack][:id])
          end
        elsif !params[:rack][:name].blank?
          if params[:rack][:name] != existing.rack.name
            rack = Rack.find_by_name(params[:rack][:name])
          end
        end
        if !rack.nil?
          existing.update_attributes(:rack => rack, :assigned_at => Time.now)
        end
      else
        # Create a new assignment
        rack = nil
        if !params[:rack][:id].blank?
          rack = Rack.find(params[:rack][:id])
        elsif !params[:rack][:name].blank?
          rack = Rack.find_by_name(params[:rack][:name])
        end
        if !rack.nil?
          RackNodeAssignment.create(:rack => rack, :node => @node)
        end
      end
    end
  end
  private :process_rack_assignment
end
