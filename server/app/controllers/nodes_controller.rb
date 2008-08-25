class NodesController < ApplicationController
  # GET /nodes
  # GET /nodes.xml
  def index
    includes = {}

    # The index page includes some data from associations.  If we don't
    # include those associations then N SQL calls result as that data is
    # looked up row by row.
    if !params[:format] || params[:format] == 'html'
      includes[:operating_system] = true
      includes[:hardware_profile] = true
      includes[:node_groups] = true
      includes[:status] = true
    end

    sort = case params['sort']
           when "name"                     then "nodes.name"
           when "name_reverse"             then "nodes.name DESC"
           when "status"                   then includes[:status] = true; "statuses.name"
           when "status_reverse"           then includes[:status] = true; "statuses.name DESC"
           when "hardware_profile"         then includes[:hardware_profile] = true; "hardware_profiles.name"
           when "hardware_profile_reverse" then includes[:hardware_profile] = true; "hardware_profiles.name DESC"
           when "operating_system"         then includes[:operating_system] = true; "operating_systems.name"
           when "operating_system_reverse" then includes[:operating_system] = true; "operating_systems.name DESC"
           end
    
    # if a sort was not defined we'll make one default
    if sort.nil?
      params['sort'] = Node.default_search_attribute
      sort = 'nodes.' + Node.default_search_attribute
    end
    
    # Parse all other params as search query args
    #
    # If the query arg is prefaced by "exact_" then we do an exact match,
    # otherwise we do a substring match.
    #
    # The user can specify more than one possible value for a given key
    # by adding an arbitrary unique identifier in square brackets after
    # each instance of the key.  In that case Rails passes us the values
    # in a hash associated with that key in params.  (See the "Parameters"
    # section of the ActionController::Base docs for more info.)  Or by
    # adding empty square brackets after the key, in which case Rails
    # passes us the values in an array associated with that key in params.
    # (This behavior seems to be undocumented.)
    #
    # The user can also specify queries against any other table that we
    # have a relationship with (i.e. something defined via belongs_to/has_*
    # in the node model).
    #
    # Searches across multiple keys are combined with AND
    #
    # Some example query args:
    # name=foo (expands to nodes.name LIKE '%foo%')
    # exact_name=foo (expands to nodes.name = 'foo')
    # name[1]=foo&name[2]=bar (expands to (nodes.name LIKE '%foo%' OR nodes.name LIKE '%bar%'))
    # name[]=foo&name[]=bar (expands to (nodes.name LIKE '%foo%' OR nodes.name LIKE '%bar%'))
    # exact_name[1]=foo&exact_name[2]=bar (expands to nodes.name IN ('foo','bar'))
    # status=Active (expands to statuses.name LIKE '%Active%')
    # network_interfaces[hardware_address]=FF:AA (expands to network_interfaces.hardware_address LIKE '%FF:AA%')
    # exact_name=foo&exact_status=Active (expands to nodes.name = 'foo' AND statuses.name = 'Active')
    searchquery = {}
    joins = {}
    # You need to specify a special join if your assosciation uses a
    # non-standard foreign key (i.e. you specified a :foreign_key when
    # defining the association).
    # 
    # The Rails :include mechanism is not deterministic enough in creating
    # table aliases for us to handle this situation automatically.
    # (See the "Table Aliasing" section of the
    # ActiveRecord::Associations::ClassMethods docs for more info.)
    # 
    # Based on the way the Rails and the code below interact your table
    # alias (JOIN table AS alias) needs to be the plural of the search
    # key the user will be using.  The search key doesn't have to match
    # the name of the association in the model, but sticking with that
    # will be way less confusing for everyone.
    special_joins = {
      'preferred_operating_system' =>
        'LEFT OUTER JOIN operating_systems AS preferred_operating_systems ON nodes.preferred_operating_system_id = preferred_operating_systems.id'
    }
    content_column_names = Node.content_columns.collect { |c| c.name }
    params.each_pair do |key, value|
      next if key == 'action'
      next if key == 'controller'
      next if key == 'format'
      next if key == 'page'
      next if key == 'sort'

      if content_column_names.include?(key) && !value.empty?
        # We have to disambiguate the column name here (by specifying
        # 'nodes.') in case the user also searches on or we otherwise join
        # to an associated table, as it might also have a column with the
        # same name.
        search_values = []
        if value.kind_of? Hash
          value.each_value { |v| search_values.push('%' + v + '%') }
        elsif value.kind_of? Array
          value.each { |v| search_values.push('%' + v + '%') }
        else
          search_values.push('%' + value + '%')
        end
        searchquery["nodes.#{key} LIKE ?"] = search_values
      elsif key =~ /^exact_(.+)$/ && content_column_names.include?($1) && !value.empty?
        if value.kind_of? Hash
          searchquery["nodes.#{$1} IN (?)"] = value.values
        elsif value.kind_of? Array
          searchquery["nodes.#{$1} IN (?)"] = value
        else
          searchquery["nodes.#{$1} = ?"] = value
        end
      elsif !value.empty?
        # This section handles any search queries which aren't in the main
        # table.  We check to ensure the user is referring to an associated
        # value defined via belongs_to/has_*

        # We use find's :include by default (since it handles the
        # join automagically), but special cases can be defined via the
        # special_joins hash above, in which case we use find's :joins.

        # The user can specify a complete column name like status[name],
        # or just the name of the relationship in which case we use the
        # model's default_search_attribute as the column name.
        # Possible formats the user might use, see comments above about
        # the various formats for specifying more than one value:
        # status=inservice
        # status[1]=inservice
        # status[]=inservice
        # status[name]=inservice
        # status[name][1]=inservice
        # status[name][]=inservice
        # And each of those could be preceeded by exact_

        search_key = nil
        exact_search = nil
        if (key =~ /^exact_(.+)/)
          search_key = $1
          exact_search = true
        else
          search_key = key
          exact_search = false
        end

        assoc = Node.reflect_on_association(search_key.to_sym)
        if assoc.nil?
          # FIXME: Need better error handling for XML users
          flash[:error] = "Ignored invalid search key #{key}"
          logger.info "Ignored invalid search key #{key}"
          next
        end

        if (special_joins.include? search_key)
          joins[special_joins[search_key]] = true
        else
          includes[search_key.to_sym] = true
        end
        table_name = search_key.tableize
        
        search = {}
        # Figure out if the user specified a search column
        # status=inservice
        # status[]=inservice
        if value.kind_of?(String) || value.kind_of?(Array)
          search["#{table_name}.#{assoc.klass.default_search_attribute}"] = value
        # status[1]=inservice
        # status[name]=inservice
        # status[name][1]=inservice
        # status[name][]=inservice
        elsif value.kind_of?(Hash)
          assoc_content_column_names = assoc.klass.content_columns.collect { |c| c.name }
          # This is a bit messy as we have to disambiguate the first two
          # possibilities.
          if value.values.first.kind_of?(String)
            if !assoc_content_column_names.include?(value.keys.first)
              # The first hash key isn't a valid column name in the
              # association, so assume this is like the first example
              search["#{table_name}.#{assoc.klass.default_search_attribute}"] = value.values
            else
              value.each_pair do |search_column,search_value|
                if assoc_content_column_names.include?(search_column)
                  search["#{table_name}.#{search_column}"] = search_value
                else
                  # FIXME: Need better error handling for XML users
                  flash[:error] = "Ignored invalid search key #{key}"
                  logger.info "Ignored invalid search key #{key}"
                end
              end
            end
          elsif value.values.first.kind_of?(Array)
            value.each_pair do |search_column,search_value|
              if assoc_content_column_names.include?(search_column)
                search["#{table_name}.#{search_column}"] = search_value
              else
                # FIXME: Need better error handling for XML users
                flash[:error] = "Ignored invalid search key #{key}"
                logger.info "Ignored invalid search key #{key}"
              end
            end
          elsif value.values.first.kind_of?(Hash)
            value.each_pair do |search_column,search_value|
              if assoc_content_column_names.include?(search_column)
                search["#{table_name}.#{search_column}"] = search_value.values
              else
                # FIXME: Need better error handling for XML users
                flash[:error] = "Ignored invalid search key #{key}"
                logger.info "Ignored invalid search key #{key}"
              end
            end
          end
        end            
        
        search.each_pair do |skey,svalue|
          if svalue.empty?
            logger.info "Search value for #{skey} is empty"
          else
            if exact_search
              if svalue.kind_of? Array
                searchquery["#{skey} IN (?)"] = svalue
              else
                searchquery["#{skey} = ?"] = svalue
              end
            else
              if svalue.kind_of? Array
                search_values = []
                svalue.each { |v| search_values.push('%' + v + '%')}
                searchquery["#{skey} LIKE ?"] = search_values
              else
                searchquery["#{skey} LIKE ?"] = '%' + svalue + '%'
              end
            end
          end
        end
      else
        logger.info "Search value for #{key} is empty"
      end
    end
    
    # The data we render to XML includes some data from associations.
    # If we don't include those associations then N SQL calls result
    # as that data is looked up row by row.
    if params[:format] && params[:format] == 'xml'
      includes[:status] = true
      includes[:operating_system] = true
      #includes[:preferred_operating_system] = true
      includes[:hardware_profile] = true
      includes[[:network_interfaces => :ip_addresses]] = true
      includes[:node_groups] = true
      includes[:comments] = true
    end
    
    logger.info "searchquery" + searchquery.to_yaml
    logger.info "includes" + includes.keys.to_yaml
    logger.info "joins" + joins.keys.to_yaml

    if searchquery.empty?
      # XML doesn't get pagination
      if params[:format] && params[:format] == 'xml'
        @objects = Node.find(:all,
                             :include => includes.keys,
                             :joins => joins.keys.join(' '),
                             :order => sort)
      else
        @objects = Node.paginate(:all,
                                 :include => includes.keys,
                                 :joins => joins.keys.join(' '),
                                 :order => sort,
                                 :page => params[:page])
      end
    else
      # Params like name[1]=foo&name[2]=bar&exact_status=Active
      # will be inserted into searchquery like this:
      # {
      #   'nodes.name LIKE ?' => ['%foo%','%bar%']
      #   'statuses.name = ?' => 'Active'
      # }
      # We need to turn that into a valid SQL query, in this case:
      # (nodes.name LIKE ? OR nodes.name LIKE ?) AND statuses.name = ?
      # and an array of search values ['%foo%','%bar%','Active']
      conditions_query = []
      conditions_values = []
      searchquery.each_pair do |key, value|
        if value.kind_of? Array
          conditions_tmp = []
          value.each do |v|
            conditions_tmp.push(key)
            conditions_values.push(v)
          end
          conditions_query.push( '(' + conditions_tmp.join(' OR ') + ')' )
        else
          conditions_query.push(key)
          conditions_values.push(value)
        end
      end
      conditions_string = conditions_query.join(' AND ')
      # XML doesn't get pagination
      if params[:format] && params[:format] == 'xml'
        @objects = Node.find(:all,
                             :include => includes.keys,
                             :joins => joins.keys.join(' '),
                             :conditions => [ conditions_string, *conditions_values ],
                             :order => sort)
      else
        @objects = Node.paginate(:all,
                                 :include => includes.keys,
                                 :joins => joins.keys.join(' '),
                                 :conditions => [ conditions_string, *conditions_values ],
                                 :order => sort,
                                 :page => params[:page])
      end
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @objects.to_xml(
                               :include => {
                                 :status => {},
                                 :operating_system => {},
                                 :preferred_operating_system => {},
                                 :hardware_profile => {},
                                 :network_interfaces => { :include => :ip_addresses },
                                 :node_groups => {},
                                 :comments => {},
                                 },
                             :dasherize => false) }
    end
  end

  # GET /nodes/1
  # GET /nodes/1.xml
  def show
    includes = {}
    # The data we render to XML includes some data from associations.
    # If we don't include those associations then N SQL calls result
    # as that data is looked up row by row.
    if params[:format] && params[:format] == 'xml'
      includes[:status] = true
      includes[:operating_system] = true
      #includes[:preferred_operating_system] = true
      includes[:hardware_profile] = true
      includes[[:network_interfaces => :ip_addresses]] = true
      includes[:node_groups] = true
      includes[:comments] = true
    end

    @node = Node.find(params[:id],
                      :include => includes.keys)

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @node.to_xml(
                             :include => {
                               :status => {},
                               :operating_system => {},
                               :preferred_operating_system => {},
                               :hardware_profile => {},
                               :network_interfaces => { :include => :ip_addresses },
                               :node_groups => {},
                               :comments => {},
                               },
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

    @node = Node.new(params[:node])

    respond_to do |format|
      if @node.save
        # If the user specified some network interface info then handle that
        # We have to perform this after saving the new node so that the
        # NICs can be associated with it.
        process_network_interfaces
        # If the user specified a rack assignment then handle that
        process_rack_assignment
        
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

    # If the user specified some network interface info then handle that
    process_network_interfaces
    # If the user specified a rack assignment then handle that
    process_rack_assignment

    respond_to do |format|
      if @node.update_attributes(params[:node])
        flash[:notice] = 'Node was successfully updated.'
        format.html { redirect_to node_url(@node) }
        format.xml  { head :ok }
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
    @node = Node.find_with_deleted(params[:id])
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
  
  def process_network_interfaces
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

    end # if params.include?(:network_interfaces)
  end
  private :process_network_interfaces

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
          existing.update_attributes(:rack => rack)
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
