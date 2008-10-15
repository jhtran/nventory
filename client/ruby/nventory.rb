require 'facter'
require 'net/http'
require 'net/https'
require 'cgi'
require 'rexml/document'
require 'yaml'

# clean up "using default DH parameters" warning for https
# http://blog.zenspider.com/2008/05/httpsssl-warning-cleanup.html
class Net::HTTP
  alias :old_use_ssl= :use_ssl=
  def use_ssl= flag
    self.old_use_ssl = flag
    @ssl_context.tmp_dh_callback = proc {}
  end
end

# Module and class names are constants, and thus have to start with a
# capital letter.
module NVentory
end

class NVentory::Client
  def initialize(debug=false, dryrun=false)
    @debug = debug
    @dryrun = dryrun
    @write_http = nil
    @read_http = nil
    @server = 'http://nventory'
    @ca_file = nil
    @ca_path = nil

    ['/etc/nventory.conf', "#{ENV['HOME']}/.nventory.conf"].each do |configfile|
      if File.exist?(configfile)
        IO.foreach(configfile) do |line|
          line.chomp!
          next if (line =~ /^\s*$/);  # Skip blank lines
          next if (line =~ /^\s*#/);  # Skip comments
          key, value = line.split(/\s*=\s*/, 2)
          if key == 'server'
            @server = value

            # Warn the user, as this could potentially be confusing
            # if they don't realize there's a config file lying
            # around
            warn "Using server #{@server} from #{configfile}"
          elsif key == 'ca_file'
            @ca_file = value
            warn "Using ca_file #{@ca_file} from #{configfile}" if (@debug)
          elsif key == 'ca_path'
            @ca_path = value
            warn "Using ca_path #{@ca_path} from #{configfile}" if (@debug)
          end
        end
      end
    end

	# Make sure the server URL ends in a / so that we can append paths
	# to it
    if @server !~ %r{/$}
      @server << '/'
    end
  end

  def get_objects(objecttype, get, exactget, includes=nil, login=nil)
    #
    # Package up the search parameters in the format the server expects
    #

    metaget = []
    if get
      get.each_pair do |key,values|
        if values.length > 1
          values.each do |value|
            metaget << "#{key}[]=#{CGI.escape(value)}"
          end
        else
          # This isn't strictly necessary, specifying a single value via
          # 'key[]=[value]' would work fine, but this makes for a cleaner URL
          # and slightly reduced processing on the backend
          metaget << "#{key}=#{CGI.escape(values[0])}"
        end
      end
    end
    if exactget
      exactget.each_pair do |key,values|
        if values.length > 1
          values.each do |value|
            metaget << "exact_#{key}[]=#{CGI.escape(value)}"
          end
        else
          # This isn't strictly necessary, specifying a single value via
          # 'key[]=[value]' would work fine, but this makes for a cleaner URL
          # and slightly reduced processing on the backend
          metaget << "exact_#{key}=#{CGI.escape(values[0])}"
        end
      end
    end
    if includes
      # includes = ['status', 'rack:datacenter']
      # maps to
      # include[status]=&include[rack]=datacenter
      includes.each do |inc|
        incstring = ''
        if inc.include?(':')
          incparts = inc.split(':')
          lastpart = incparts.pop
          incstring = 'include'
          incparts.each { |part| incstring << "[#{part}]" }
          incstring << "=#{lastpart}"
        else
          incstring = "include[#{inc}]="
        end
        metaget << incstring
      end
    end

    querystring = metaget.join('&')

    #
    # Send the query to the server
    #

    http = get_http(login)
	uri = URI::join(@server, "#{objecttype}.xml?#{querystring}")
    req = Net::HTTP::Get.new(uri.path, @headers)
    warn "GET URL: #{uri.path}" if (@debug)
    response = http.request(req)
    if !response.kind_of?(Net::HTTPOK)
      puts response.body
      response.error!
    end

    #
    # Parse the XML data from the server
    # This tries to render the XML into the best possible representation
    # as a Perl hash.  It may need to evolve over time.
    #

    puts response.body if (@debug)
    results_xml = REXML::Document.new(response.body)
    results = {}
    if results_xml.root.elements["/#{objecttype}"]
      results_xml.root.elements["/#{objecttype}"].each do |elem|
        # For some reason Elements[] is returning things other than elements,
        # like text nodes
        next if elem.node_type != :element
        data = xml_to_ruby(elem)
        name = data['name'] || data['id']
        results[name] = data
      end
    end

    #puts results.inspect if (@debug)
    puts YAML.dump(results) if (@debug)
    results
  end

  def get_field_names(objecttype, login=nil)
    http = get_http(login)
	uri = URI::join(@server, "#{objecttype}/field_names.xml")
    req = Net::HTTP::Get.new(uri.path, @headers)
    warn "GET URL: #{uri.path}" if (@debug)
    response = http.request(req)
    if !response.kind_of?(Net::HTTPOK)
      puts response.body
      response.error!
    end

    puts response.body if (@debug)
    results_xml = REXML::Document.new(response.body)
    field_names = []
    results_xml.root.elements['/field_names'].each do |elem|
      # For some reason Elements[] is returning things other than elements,
      # like text nodes
      next if elem.node_type != :element
      field_names << elem.text
    end

    field_names
  end

  def get_expanded_nodegroup(nodegroup)
    results = get_objects('node_groups', {}, {'name' => [nodegroup]}, ['nodes', 'child_groups'])
    nodes = {}
    if results.has_key?(nodegroup)
      results[nodegroup]['nodes'].each { |node| nodes[node['name']] = true }
      results[nodegroup]['child_groups'].each do |child_group|
        get_expanded_nodegroup(child_group['name']).each { |child_group_node| nodes[child_group_node] = true }
      end
    end
    nodes.keys.sort
  end

  # The results argument can be a reference to a hash returned by a
  # call to get_objects, in which case the data will be PUT to each object
  # there, thus updating them.  Or it can be 'undef', in which case the
  # data will be POSTed to create a new entry.
  def set_objects(objecttypes, results, data, login, password_callback=nil)
    objecttype = singularize(objecttypes)
    # Convert any keys which don't already specify a model
    # from 'foo' to 'objecttype[foo]'
    cleandata = {}
    data.each_pair do |key, value|
      if key !~ /\[.+\]/
        cleandata["#{objecttype}[#{key}]"] = value
      else
        cleandata[key] = value
      end
    end

    #puts cleandata.inspect if (@debug)
    puts YAML.dump(cleandata) if (@debug)

    if results && !results.empty?
      results.each_pair do |result_name, result|
        # PUT to update an existing object
        if result['id']
          http = get_http(login, password_callback)
          uri = URI::join(@server, "#{objecttypes}/#{result['id']}.xml")
          req = Net::HTTP::Put.new(uri.path, @headers)
          req.set_form_data(cleandata)
          warn "PUT to URL: #{uri.path}" if (@debug)
          if !@dryrun
            response = http.request(req)
            # FIXME: Aborting partway through a multi-node action is probably
            # not ideal behavior
            if !response.kind_of?(Net::HTTPOK)
              puts response.body
              response.error!
            end
          end
        else
          warn "set_objects passed a bogus results hash, #{result_name} has no id field"
        end
      end
    else
      http = get_http(login, password_callback)
      uri = URI::join(@server, "#{objecttypes}.xml")
      req = Net::HTTP::Post.new(uri.path, @headers)
      req.set_form_data(cleandata)
      warn "POST to URL: #{uri.path}" if (@debug)
      if !@dryrun
        response = http.request(req)
        if !response.kind_of?(Net::HTTPCreated)
          puts response.body
          response.error!
        end
      end
    end
  end

  def register
    data = {}

    # Tell facter to load everything, otherwise it tries to dynamically
    # load the individual fact libraries using a very broken mechanism
    Facter.loadfacts

    #
    # Gather software-related information
    #
    data['name'] = Facter['fqdn'].value
    if Facter['kernel'] && Facter['kernel'].value == 'Linux'
      # Strip release version and code name from lsbdistdescription
      lsbdistdesc = Facter['lsbdistdescription'].value
      lsbdistdesc.gsub!(/ release \S+/, '')
      lsbdistdesc.gsub!(/ \([^)]\)/, '')
      data['operating_system[variant]'] = lsbdistdesc
      data['operating_system[version_number]'] = Facter['lsbdistrelease'].value
    elsif Facter['kernel'] && Facter['kernel'].value == 'Darwin' &&
          Facter['macosx_productname'] && Facter['macosx_productname'].value
        data['operating_system[variant]'] = Facter['macosx_productname'].value
        data['operating_system[version_number]'] = Facter['macosx_productversion'].value
    else
      data['operating_system[variant]'] = Facter['operatingsystem'].value
      data['operating_system[version_number]'] = Facter['operatingsystemrelease'].value
    end
    if Facter['architecture'] && Facter['architecture'].value
      data['operating_system[architecture]'] = Facter['architecture'].value
    else
      # Not sure if this is reasonable
      data['operating_system[architecture]'] = Facter['hardwaremodel'].value
    end
    data['kernel_version'] = Facter['kernelrelease'].value
    if Facter['memorysize'] && Facter['memorysize'].value
      data['os_memory'] = Facter['memorysize'].value
    elsif Facter['sp_physical_memory'] && Facter['sp_physical_memory'].value  # Mac OS X
      # More or less a safe bet that OS memory == physical memory on Mac OS X
      data['os_memory'] = Facter['sp_physical_memory'].value
    end
    if Facter['swapsize']
      data['swap'] = Facter['swapsize'].value
    end
    # Currently the processorcount fact doesn't even get defined on most platforms
    if Facter['processorcount'] && Facter['processorcount'].value
      # This is generally a virtual processor count (cores and HTs),
      # not a physical CPU count
      data['os_processor_count'] = Facter['processorcount'].value
    elsif Facter['sp_number_processors'] && Facter['sp_number_processors'].value
      data['os_processor_count'] = Facter['sp_number_processors'].value
    end
    # Need custom facts for these
    #data['timezone'] = 
    #data['virtual_client_ids'] = 

    #
    # Gather hardware-related information
    #

    if Facter['manufacturer'] && Facter['manufacturer'].value  # dmidecode
      data['hardware_profile[manufacturer]'] = Facter['manufacturer'].value
      data['hardware_profile[model]'] = Facter['productname'].value
    elsif Facter['sp_machine_name'] && Facter['sp_machine_name'].value  # Mac OS X
      # There's a small chance of this not being true...
      data['hardware_profile[manufacturer]'] = 'Apple'
      data['hardware_profile[model]'] = Facter['sp_machine_name'].value
    else
      data['hardware_profile[manufacturer]'] = 'Unknown'
      data['hardware_profile[model]'] = 'Unknown'
    end
    if Facter['serialnumber'] && Facter['serialnumber'].value
      data['serial_number'] = Facter['serialnumber'].value
    elsif Facter['sp_serial_number'] && Facter['sp_serial_number'].value # Mac OS X
      data['serial_number'] = Facter['sp_serial_number'].value
    end
    if Facter['processor0'] && Facter['processor0'].value
      # FIXME: Parsing this string is less than ideal, as these things
      # are reported as seperate fields by dmidecode, but facter isn't
      # reading that data.
      # Example: Intel(R) Core(TM)2 Duo CPU     T7300  @ 2.00GHz
      # Example: Intel(R) Pentium(R) 4 CPU 3.60GHz
      processor = Facter['processor0'].value
      if cpu_type =~ /(\S+)\s(.+)/
        manufacturer = $1
        model = $2
        speed = nil
        if model =~ /(.+\S)\s+\@\s+([\d\.]+.Hz)/
          model = $1
          speed = $2
        elsif model =~ /(.+\S)\s+([\d\.]+.Hz)/
          model = $1
          speed = $2
        end
        data['processor_manufacturer'] = manufacturer.gsub(/\(R\)/, '')
        data['processor_model'] = model
        data['processor_speed'] = speed
      end
    elsif Facter['sp_cpu_type'] && Facter['sp_cpu_type'].value
      # FIXME: Assuming the manufacturer is the first word is
      # less than ideal
      cpu_type = Facter['sp_cpu_type'].value
      if cpu_type =~ /(\S+)\s(.+)/
        data['processor_manufacturer'] = $1
        data['processor_model'] = $2
      end
      data['processor_speed'] = Facter['sp_current_processor_speed'].value
      # It's not clear if system_profiler is reporting the number
      # of physical CPUs or the number seen by the OS.  I'm not
      # sure if there are situations in Mac OS where those two can
      # get out of sync.  As such this is identical to what is reported
      # for the os_processor_count above.
      data['processor_count'] = Facter['sp_number_processors'].value
    end
      
    #data['processor_count'] = 
    #data['processor_core_count'] = 
    #data['processor_socket_count'] = 
    #data['power_supply_count'] = 
    #data['physical_memory'] = 
    #data['physical_memory_sizes'] = 

    if Facter['interfaces'] && Facter['interfaces'].value
      Facter['interfaces'].value.split(',').each do |nic|
        data["network_interfaces[#{nic}][name]"] = nic
        data["network_interfaces[#{nic}][hardware_address]"] = Facter["macaddress_#{nic}"].value
        #data["network_interfaces[#{nic}][interface_type]"] = 
        #data["network_interfaces[#{nic}][physical]"] = 
        #data["network_interfaces[#{nic}][up]"] = 
        #data["network_interfaces[#{nic}][link]"] = 
        #data["network_interfaces[#{nic}][autonegotiate]"] = 
        #data["network_interfaces[#{nic}][speed]"] = 
        #data["network_interfaces[#{nic}][full_duplex]"] = 
        # Facter only captures one address per interface
        data["network_interfaces[#{nic}][ip_addresses][0][address]"] = Facter["ipaddress_#{nic}"].value
        data["network_interfaces[#{nic}][ip_addresses][0][address_type]"] = 'ipv4'
        data["network_interfaces[#{nic}][ip_addresses][0][netmask]"] = Facter["netmask_#{nic}"].value
        #data["network_interfaces[#{nic}][ip_addresses][0][broadcast]"] = 
      end
    end
    # Mark our NIC data as authoritative so that the server properly
    # updates its records (removing any NICs and IPs we don't specify)
    data['network_interfaces[authoritative]'] = true

    if Facter['uniqueid'] && Facter['uniqueid'].value
      # This sucks, it's just using hostid, which is generally tied to an
      # IP address, not the physical hardware
      data['uniqueid'] = Facter['uniqueid'].value
    elsif Facter['sp_serial_number'] && Facter['sp_serial_number'].value
      # I imagine Mac serial numbers are unique
      data['uniqueid'] = Facter['sp_serial_number'].value
    end

    if data['hardware_profile[model]'] == 'VMware Virtual Platform'
      results = get_objects('nodes', {'virtual_client_ids' => [data['uniqueid']]}, {}, [], 'autoreg')
      if results.length == 1
        data['virtual_parent_node_id'] = results.values.first['id']
      elsif results.length > 1
        warn "Multiple hosts claim this virtual client: #{results.keys.sort.join(',')}"
      end
    end

    #
    # Report data to server
    #

    # Check to see if there's an existing entry for this host that matches
    # our unique id.  If so we want to update it, even if the hostname
    # doesn't match our current hostname (as it probably indicates this
    # host was renamed).
    results = nil
    if data['uniqueid']
      results = get_objects('nodes', {}, {'uniqueid' => [data['uniqueid']]}, [], 'autoreg')
    end

    # If we failed to find an existing entry based on the unique id
    # fall back to the hostname.  This may still fail to find an entry,
    # if this is a new host, but that's OK as it will leave %results
    # as undef, which triggers set_nodes to create a new entry on the
    # server.
    if !results && data['name']
      results = get_objects('nodes', {}, {'name' => [data['name']]}, [], 'autoreg')
    end

    set_objects('nodes', results, data, 'autoreg')
  end

  # The first argument is a hash returned by a 'nodes' call to get_objects
  # The second argument is a hash returned by a 'node_groups'
  # call to get_objects
  # NOTE: For the node groups you must have requested that the server include 'nodes' in the result
  def add_nodes_to_nodegroups(nodes, nodegroups, login, password_callback)
    # The server only supports setting a complete list of members of
    # a node group.  So we need to retreive the current list of members
    # for each group, merge in the additional nodes that the user wants
    # added, and pass that off to set_nodegroup_assignments to perform
    # the update.
    # FIXME: This should talk directly to the node_group_node_assignments
    # controller, so that we aren't exposed to the race conditions this
    # method currently suffers from.
    nodegroups.each_pair do |nodegroup_name, nodegroup|
      # Use a hash to merge the current and new members and
      # eliminate duplicates
      merged_nodes = nodes

      nodegroup[nodes].each do |node|
        name = node[name]
        merged_nodes[name] = node
      end

      set_nodegroup_node_assignments(merged_nodes, {nodegroup_name => nodegroup}, login, password_callback)
    end
  end
  # The first argument is a hash returned by a 'nodes' call to get_objects
  # The second argument is a hash returned by a 'node_groups'
  # call to get_objects
  # NOTE: For the node groups you must have requested that the server include 'nodes' in the result
  def remove_nodes_from_nodegroups(nodes, nodegroups, login, password_callback)
    # The server only supports setting a complete list of members of
    # a node group.  So we need to retreive the current list of members
    # for each group, remove the nodes that the user wants
    # removed, and pass that off to set_nodegroup_assignments to perform
    # the update.
    # FIXME: This should talk directly to the node_group_node_assignments
    # controller, so that we aren't exposed to the race conditions this
    # method currently suffers from.
    nodegroups.each_pair do |nodegroup_name, nodegroup|
      desired_nodes = {}

      nodegroup[nodes].each do |node|
        name = node[name]
        if !nodes.has_key?(name)
          desired_nodes[name] = node
        end
      end

      set_nodegroup_node_assignments(desired_nodes, {nodegroup_name => nodegroup}, login, password_callback)
    end
  end
  # The first argument is a hash returned by a 'nodes' call to get_objects
  # The second argument is a hash returned by a 'node_groups'
  # call to get_objects
  def set_nodegroup_node_assignments(nodes, nodegroups, login, password_callback)
    node_ids = []
    nodes.each_pair do |node_name, node|
      if node['id']
        node_ids << node['id']
      else
        warn "set_nodegroup_node_assignments passed a bogus nodes hash, #{node_name} has no id field"
      end
    end

    nodegroupdata = {}
    nodegroupdata['node_group_node_assignments[nodes][]'] = node_ids

    set_objects('node_groups', nodegroups, nodegroupdata, login, password_callback)
  end

  # Both arguments are hashes returned by a 'node_groups' call to get_objects
  # NOTE: For the parent groups you must have requested that the server include 'child_groups' in the result
  def add_nodegroups_to_nodegroups(child_groups, parent_groups, login, password_callback)
    # The server only supports setting a complete list of assignments for
    # a node group.  So we need to retreive the current list of assignments
    # for each group, merge in the additional node groups that the user wants
    # added, and pass that off to set_nodegroup_nodegroup_assignments to perform
    # the update.
    # FIXME: This should talk directly to the node_group_node_groups_assignments
    # controller, so that we aren't exposed to the race conditions this
    # method currently suffers from.
    parent_groups.each_pair do |parent_group_name, parent_group|
      # Use a hash to merge the current and new members and
      # eliminate duplicates
      merged_nodegroups = child_groups

      parent_group[child_groups].each do |child_group|
        name = child_group[name]
        merged_nodegroups[name] = child_group
      end

      set_nodegroup_nodegroup_assignments(merged_nodegroups, {parent_group_name => parent_group}, login, password_callback)
    end
  end
  # Both arguments are hashes returned by a 'node_groups' call to get_objects
  # NOTE: For the parent groups you must have requested that the server include 'child_groups' in the result
  def remove_nodegroups_from_nodegroups(child_groups, parent_groups, login, password_callback)
    # The server only supports setting a complete list of assignments for
    # a node group.  So we need to retrieve the current list of assignments
    # for each group, remove the node groups that the user wants
    # removed, and pass that off to set_nodegroup_nodegroup_assignments to perform
    # the update.
    # FIXME: This should talk directly to the node_group_node_groups_assignments
    # controller, so that we aren't exposed to the race conditions this
    # method currently suffers from.
    parent_groups.each_pair do |parent_group_name, parent_group|
      desired_child_groups = {}

      parent_group[child_groups].each do |child_group|
        name = child_group[name]
        if !child_groups.has_key?(name)
          desired_child_groups[name] = child_group
        end
      end

      set_nodegroup_nodegroup_assignments(desired_child_groups, {parent_group_name => parent_group}, login, password_callback)
    end
  end
  # Both arguments are hashes returned by a 'node_groups' call to get_objects
  def set_nodegroup_nodegroup_assignments(child_groups, parent_groups, login, password_callback)
    child_ids = []
    child_groups.each_pair do |child_group_name, child_group|
      if child_group['id']
        child_ids << child_group['id']
      else
        warn "set_nodegroup_nodegroup_assignments passed a bogus child groups hash, #{child_group_name} has no id field"
      end
    end

    nodegroupdata = {}
    nodegroupdata['node_group_node_group_assignments[child_groups][]'] = child_ids

    set_objects('node_groups', parent_groups, nodegroupdata, login, password_callback)
  end
  
  #
  # Private methods
  #
  private
  
  def get_http(login=nil, password_callback=nil)
    if login
      return @write_http if (@write_http)
    else
      return @read_http if (@read_http)
    end

    uri = URI.parse(@server)

    cookiefile = nil
    password = nil
    if login == 'autoreg'
      cookiefile = '/root/.nventory_cookie_autoreg'
      password = 'autoreg'
      if ! File.directory?('/root')
        Dir.mkdir('/root')
      end
    else
      cookiefile = "#{ENV['HOME']}/.nventory_cookie"
    end

    # Create the cookie file if it doesn't already exist
    if !File.exist?(cookiefile)
      warn "Creating #{cookiefile}"
      File.open(cookiefile, 'w') { |file| }
    end
    # Ensure the permissions on the cookie file are appropriate,
    # as it will contain a session key that could be used by others
    # to impersonate this user to the server.
    st = File.stat(cookiefile)
    if st.mode & 07177 != 0
      warn "Correcting permissions on #{cookiefile}"
      File.chmod(st.mode & 0600, cookiefile)
    end

    warn "Using cookies from #{cookiefile}" if (@debug)
    # Sigh, Ruby doesn't have a library for handling a persistent
    # cookie store so we have to do the dirty work ourselves.  This
    # is by no means a full implementation, it's just enough to do
    # what's needed here.
    cookies = []
    IO.foreach(cookiefile) do |line|
      next if (line =~ /^\s*$/);  # Skip blank lines
      next if (line =~ /^\s*#/);  # Skip comments
      if (line =~ /^Set-Cookie\d?: (.*)/)
        data = $1
        cookie, rest = data.split('; ', 2)
        use = true
        rest.split('; ').each do |crumb|
          if crumb =~ /^domain=(.*)/
            domain = $1
            if uri.host !~ Regexp.new("#{domain}$")
              use = false
            end
          elsif crumb =~ /^path="(.*)"/
            path = $1
            if uri.path !~ Regexp.new("^#{path}")
              use = false
            end
          end
        end
        if use
          cookies << cookie
        end
      end
    end
    @headers = { 'Cookie' => cookies.join('; ') }

    http = Net::HTTP.new(uri.host, uri.port)
    https = nil
    if uri.scheme == "https"
      https = http
    else
      # FIXME: Need to provide a way for users to specify a non-standard
      # HTTPS port when they aren't using HTTPS for all activity
      https = Net::HTTP.new(uri.host, 443)
    end
    https.use_ssl = true
    if @ca_file && File.exist?(@ca_file)
      https.ca_file = @ca_file
      https.verify_mode = OpenSSL::SSL::VERIFY_PEER
    end 
    if @ca_path && File.directory?(@ca_path)
      https.ca_path = @ca_path
      https.verify_mode = OpenSSL::SSL::VERIFY_PEER
    end

    if login
      # User wants to be able to write to the server

      # First check if any existing session id works by sending
      # an empty POST to the accounts controller.  We will get
      # back a 302 redirect if we need to authenticate.  There's
      # nothing special about accounts, we could use any controller,
      # accounts just seemed appropriate.
      uri = URI::join(@server, 'accounts.xml')
      response = http.post(uri.path, '', @headers)
      if response.kind_of?(Net::HTTPFound)
        warn "POST to #{uri.path} was redirected, authenticating" if (@debug)
        # Extract cookie
        newcookieentry = response['Set-Cookie']
        # Some cookie fields are optional, and should default to the
        # values in the request.  We need to insert these so that we
        # save them properly.
        # http://cgi.netscape.com/newsref/std/cookie_spec.html
        if !newcookieentry.include?('domain=')
          newcookieentry << "; domain=#{uri.host}"
        end
        newcookie, rest = newcookieentry.split('; ', 2)
        if !cookies.include?(newcookie)
          # Update @headers
          cookies << newcookie
          @headers = { 'Cookie' => cookies.join('; ') }
          # Save cookie for the future
          warn "Updating cookiefile #{cookiefile}" if (@debug)
          File.open(cookiefile, 'a') { |file| file.puts("Set-Cookie: #{newcookieentry}") }
        end
        # Logins need to go to HTTPS
		uri = URI::join(@server, 'login/login')
        req = Net::HTTP::Post.new(uri.path, @headers)
        password = password_callback.get_password if (!password)
        req.set_form_data({'login' => login, 'password' => password})
        response = https.request(req)

        # The server always sends back a 302 redirect in response
        # to a login attempt.  You get redirected back to the login
        # page if your login failed, or redirected to your original
        # page or the main page if the login succeeded.
        locurl = nil
        if response['Location']
          locurl = URI.parse(response['Location'])
        end
        if (!response.kind_of?(Net::HTTPFound) || locurl.path == uri.path)
          warn "Authentication failed"
          if @debug
            puts response.body
            response.error!
          else
            abort
          end
        end
      end

      # Cache http object
      @write_http = http
      @read_http = http
    else
      @read_http = http
    end

    http
  end

  def xml_to_ruby(xmlnode)
    # The server includes a hint as to the type of data structure
    # in the XML
    data = nil
    if xmlnode.attributes['type'] == 'array'
      data = []
      xmlnode.elements.each { |child| data << xml_to_ruby(child) }
    elsif xmlnode.size <= 1
      data = xmlnode.text
    else
      data = {}
      xmlnode.elements.each do |child|
        field = child.name
        data[field] = xml_to_ruby(child)
      end
    end
    data
  end

  # FIXME: Would be really nice to figure out a way to use the Rails inflector
  def singularize(word)
    singular = nil
    # statuses -> status
    # ip_addresses -> ip_address
    if (word =~ /(.*s)es$/)
      singular = $1
    # nodes -> node
    # vips -> vip
    elsif (word =~ /(.*)s$/)
      singular = $1
    else
      singular = word
    end
    singular
  end

end
