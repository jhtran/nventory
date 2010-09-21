begin
  # Try loading facter w/o gems first so that we don't introduce a
  # dependency on gems if it is not needed.
  require 'facter'         # Facter
rescue LoadError
  require 'rubygems'
  require 'facter'
end
require 'uri'
require 'net/http'
require 'net/https'
require 'cgi'
require 'rexml/document'
require 'yaml'

# fix for ruby http bug where it encodes the params incorrectly
class Net::HTTP::Put
  def set_form_data(params, sep = '&')
      params_array = params.map do |k,v|
        if v.is_a? Array
          v.inject([]){|c, val| c << "#{urlencode(k.to_s)}=#{urlencode(val.to_s)}"}.join(sep)
        else
          "#{urlencode(k.to_s)}=#{urlencode(v.to_s)}"          
        end
      end
      self.body = params_array.join(sep)
      self.content_type = 'application/x-www-form-urlencoded'
  end
end

module PasswordCallback
  @@password = nil
  def self.get_password
    while !@@password
      system "stty -echo"
      print "Password: "
      @@password = $stdin.gets.chomp
      system "stty echo"
    end
    @@password
  end
end

# Module and class names are constants, and thus have to start with a
# capital letter.
module NVentory
end

CONFIG_FILES = ['/etc/nventory.conf', "#{ENV['HOME']}/.nventory.conf"]

class NVentory::Client
  attr_accessor :delete

  def initialize(data=nil,*moredata)
    if data || moredata
      parms = legacy_initializeparms(data,moredata) 
      # def initialize(debug=false, dryrun=false, configfile=nil, server=nil)
      parms[:debug] ? (@debug = parms[:debug]) : @debug = (nil)
      parms[:dryrun] ? (@dryrun = parms[:dryrun]) : @dryrun = (nil)
      parms[:server] ? (@server = parms[:server]) : @server = (nil)
      parms[:cookiefile] ? @cookiefile = parms[:cookiefile] : @cookiefile = "#{ENV['HOME']}/.nventory_cookie"
      if parms[:proxy_server] == false
        @proxy_server = 'nil'
      elsif parms[:proxy_server]
        @proxy_server = parms[:proxy_server]
      else 
        @proxy_server = nil
      end
      parms[:sso_server] ? (@sso_server = parms[:sso_server]) : (@sso_server = nil)
      parms[:configfile] ? (configfile = parms[:configfile]) : (configfile = nil)
    end
    @sso_server = 'https://sso.example.com/' unless @sso_server
    @ca_file = nil
    @ca_path = nil
    @dhparams = '/etc/nventory/dhparams'
    @delete = false  # Initialize the variable, see attr_accessor above
    
    CONFIG_FILES << configfile if configfile
 
    CONFIG_FILES.each do |configfile|
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
            warn "Using server #{@server} from #{configfile}" if (@debug)
          elsif key == 'sso_server' && !@sso_server
            @sso_server = value
            warn "Using sso_server #{@sso_server} from #{configfile}" if (@debug)
          elsif key == 'proxy_server' && !@proxy_server
            @proxy_server = value
            warn "Using proxy_server #{@proxy_server} from #{configfile}" if (@debug)
          elsif key == 'ca_file'
            @ca_file = value
            warn "Using ca_file #{@ca_file} from #{configfile}" if (@debug)
          elsif key == 'ca_path'
            @ca_path = value
            warn "Using ca_path #{@ca_path} from #{configfile}" if (@debug)
          elsif key == 'dhparams'
            @dhparams = value
            warn "Using dhparams #{@dhparams} from #{configfile}" if (@debug)
          elsif key == 'cookiefile'
            @cookiefile = value
            warn "Using cookiefile #{@cookiefile} from #{configfile}" if (@debug)
          end
        end
      end
    end

    unless @server
      @server = 'http://nventory/'
      warn "Using server #{@server}" if @debug
    end
    
    # Make sure the server URL ends in a / so that we can append paths to it
    # using URI.join
    if @server !~ %r{/$}
      @server << '/'
    end
  end

  def legacy_initializeparms(data,moredata)
    # if data is string, it is legacy method of supplying initialize params:
    # def initialize(debug=false, dryrun=false, configfile=nil, server=nil)
    newdata = {}
    if data.kind_of?(Hash)
      newdata = data
    elsif data || moredata
      newdata[:debug] = data
      newdata[:dryrun] = moredata[0]
      newdata[:configfile] = moredata[1]
      if moredata[2]
      server = moredata[2] if moredata[2]
        if server =~ /^http/
          (server =~ /\/$/) ? (newdata[:server] = server) : (newdata[:server] = "#{server}/")
        else
          newdata[:server] = "http://#{server}/"
        end
      end
      newdata[:proxy_server] = moredata[3]
    else
      raise 'Syntax Error'
    end
    warn "** Using server #{newdata[:server]} **" if newdata[:server]
    warn "** Using proxy_server #{newdata[:proxy_server]} **" if newdata[:proxy_server]
    return newdata
  end

  def legacy_getparms(data,moredata)
    # if data is string, it is legacy method of supplying get_objects params:
    # def get_objects(objecttype, get, exactget, regexget, exclude, andget, includes=nil, login=nil, password_callback=PasswordCallback)
    newdata = {}
    if data.kind_of?(String)
      raise 'Syntax Error: Missing :objecttype' unless data.kind_of?(String)
      newdata[:objecttype] = data
      newdata[:get] = moredata[0]
      newdata[:exactget] = moredata[1]
      newdata[:regexget] = moredata[2]
      newdata[:exclude] = moredata[3]
      newdata[:andget] = moredata[4]
      newdata[:includes] = moredata[5] 
      newdata[:login] = moredata[6] 
      newdata[:password_callback] = PasswordCallback
    elsif data.kind_of?(Hash) 
      raise 'Syntax Error: Missing :objecttype' unless data[:objecttype].kind_of?(String)
      newdata = data
      newdata[:password_callback] = PasswordCallback unless newdata[:password_callback]
    else
      raise 'Syntax Error'
    end
    return newdata
  end
  
  # FIXME: get, exactget, regexget, exclude and includes should all merge into
  # a single search options hash parameter
  def get_objects(data,*moredata)
    parms = legacy_getparms(data,moredata)
    # def get_objects(objecttype, get, exactget, regexget, exclude, andget, includes=nil, login=nil, password_callback=PasswordCallback)
    objecttype = parms[:objecttype]
    get = parms[:get]
    exactget = parms[:exactget]
    regexget = parms[:regexget]
    exclude = parms[:exclude]
    andget = parms[:andget]
    includes = parms[:includes]
    login = parms[:login]
    password_callback = parms[:password_callback]
    # PS-704 - node_groups controller when format.xml, includes some custom model methods that create a lot of querying joins, so this is 
      # a way to 'override' it on cli side - the server will look for that param to skip these def methods when it renders.  webparams = {:nodefmeth => 1}
    webparams = parms[:webparams]
    #
    # Package up the search parameters in the format the server expects
    #
    metaget = []
    if get
      get.each_pair do |key,values|
        if key == 'enable_aliases' && values == 1
          metaget << "#{key}=#{values}"
        elsif values.length > 1
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
        if key == 'enable_aliases' && values == 1
          metaget << "#{key}=#{values}"
        elsif values.length > 1
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
    if regexget
      regexget.each_pair do |key,values|
        if values.length > 1
          values.each do |value|
            metaget << "regex_#{key}[]=#{CGI.escape(value)}"
          end
        else
          # This isn't strictly necessary, specifying a single value via
          # 'key[]=[value]' would work fine, but this makes for a cleaner URL
          # and slightly reduced processing on the backend
          metaget << "regex_#{key}=#{CGI.escape(values[0])}"
        end
      end
    end
    if exclude
      exclude.each_pair do |key,values|
        if values.length > 1
          values.each do |value|
            metaget << "exclude_#{key}[]=#{CGI.escape(value)}"
          end
        else
          # This isn't strictly necessary, specifying a single value via
          # 'key[]=[value]' would work fine, but this makes for a cleaner URL
          # and slightly reduced processing on the backend
          metaget << "exclude_#{key}=#{CGI.escape(values[0])}"
        end
      end
    end
    if andget
      andget.each_pair do |key,values|
        if values.length > 1
          values.each do |value|
            metaget << "and_#{key}[]=#{CGI.escape(value)}"
          end
        else
          # This isn't strictly necessary, specifying a single value via
          # 'key[]=[value]' would work fine, but this makes for a cleaner URL
          # and slightly reduced processing on the backend
          metaget << "and_#{key}=#{CGI.escape(values[0])}"
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
    if webparams && webparams.kind_of?(Hash)
      webparams.each_pair{|k,v| metaget << "#{k}=#{v}"}
    end  

    querystring = metaget.join('&')

    #
    # Send the query to the server
    #

    uri = URI::join(@server, "#{objecttype}.xml?#{querystring}")
    req = Net::HTTP::Get.new(uri.request_uri)
    warn "GET URL: #{uri}" if (@debug)
    response = send_request(req, uri, login, password_callback)
    while response.kind_of?(Net::HTTPMovedPermanently)
      uri = URI.parse(response['Location'])
      req = Net::HTTP::Get.new(uri.request_uri)
      response = send_request(req, uri, login, password_callback)
    end
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

  def get_field_names(objecttype, login=nil, password_callback=PasswordCallback)
    uri = URI::join(@server, "#{objecttype}/field_names.xml")
    req = Net::HTTP::Get.new(uri.request_uri)
    warn "GET URL: #{uri}" if (@debug)
    response = send_request(req, uri, login, password_callback)
    while response.kind_of?(Net::HTTPMovedPermanently)
      uri = URI.parse(response['Location'])
      req = Net::HTTP::Get.new(uri.request_uri)
      response = send_request(req, uri, login, password_callback)
    end  
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
    getdata = {}
    getdata[:objecttype] = 'node_groups'
    getdata[:exactget] = {'name' => [nodegroup]}
    getdata[:includes] = ['nodes', 'child_groups']
    results = get_objects(getdata)
    nodes = {}
    if results.has_key?(nodegroup)
      if results[nodegroup].has_key?('nodes')
        results[nodegroup]['nodes'].each { |node| nodes[node['name']] = true }
      end
      if results[nodegroup].has_key?('child_groups')
        results[nodegroup]['child_groups'].each do |child_group|
          get_expanded_nodegroup(child_group['name']).each { |child_group_node| nodes[child_group_node] = true }
        end
      end
    end
    nodes.keys.sort
  end

  # The results argument can be a reference to a hash returned by a
  # call to get_objects, in which case the data will be PUT to each object
  # there, thus updating them.  Or it can be nil, in which case the
  # data will be POSTed to create a new entry.
  def set_objects(objecttypes, results, data, login, password_callback=PasswordCallback)
    # Convert any keys which don't already specify a model
    # from 'foo' to 'objecttype[foo]'
    objecttype = singularize(objecttypes)
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

    successcount = 0
    if results && !results.empty?
      results.each_pair do |result_name, result|
        if @delete
          warn "Deleting objects via set_objects is deprecated, use delete_objects instead"
          uri = URI::join(@server, "#{objecttypes}/#{result['id']}.xml")
          req = Net::HTTP::Delete.new(uri.request_uri)
          req.set_form_data(cleandata)
          response = send_request(req, uri, login, password_callback)
          while response.kind_of?(Net::HTTPMovedPermanently)
            uri = URI.parse(response['Location'])
            req = Net::HTTP::Delete.new(uri.request_uri)
            response = send_request(req, uri, login, password_callback)
          end  
          if response.kind_of?(Net::HTTPOK)
            successcount += 1
          else
            puts "DELETE to #{uri} failed for #{result_name}:"
            puts response.body
          end
        # PUT to update an existing object
        elsif result['id']
          uri = URI::join(@server, "#{objecttypes}/#{result['id']}.xml")
          req = Net::HTTP::Put.new(uri.request_uri)
          req.set_form_data(cleandata)
          warn "PUT to URL: #{uri}" if (@debug)
          if !@dryrun
            response = send_request(req, uri, login, password_callback)
            while response.kind_of?(Net::HTTPMovedPermanently)
              uri = URI.parse(response['Location'])
              req = Net::HTTP::Put.new(uri.request_uri)
              req.set_form_data(cleandata)
              response = send_request(req, uri, login, password_callback)
            end
            if response.kind_of?(Net::HTTPOK)
              successcount += 1
            else
              puts "PUT to #{uri} failed for #{result_name}:"
              puts response.body
            end
          end
        else
          warn "set_objects passed a bogus results hash, #{result_name} has no id field"
        end
      end
    else
      uri = URI::join(@server, "#{objecttypes}.xml")
      req = Net::HTTP::Post.new(uri.request_uri)
      req.set_form_data(cleandata)
      warn "POST to URL: #{uri}" if (@debug)
      if !@dryrun
        response = send_request(req, uri, login, password_callback)
        while response.kind_of?(Net::HTTPMovedPermanently)
          uri = URI.parse(response['Location'])
          req = Net::HTTP::Post.new(uri.request_uri)
          req.set_form_data(cleandata)
          response = send_request(req, uri, login, password_callback)
        end  
        if response.kind_of?(Net::HTTPOK) || response.kind_of?(Net::HTTPCreated)
          successcount += 1
        else
          puts "POST to #{uri} failed."
          puts response.body
        end
      end
    end
    
    successcount
  end
  
  # The results argument should be a reference to a hash returned by a
  # call to get_objects.
  def delete_objects(objecttypes, results, login, password_callback=PasswordCallback)
    successcount = 0
    results.each_pair do |result_name, result|
      if result['id']
        uri = URI::join(@server, "#{objecttypes}/#{result['id']}.xml")
        req = Net::HTTP::Delete.new(uri.request_uri)
        response = send_request(req, uri, login, password_callback)
        while response.kind_of?(Net::HTTPMovedPermanently)
          uri = URI.parse(response['Location'])
          req = Net::HTTP::Delete.new(uri.request_uri)
          response = send_request(req, uri, login, password_callback)
        end  
        if response.kind_of?(Net::HTTPOK)
          successcount = 0
        else
          warn "Delete of #{result_name} (#{result['id']}) failed:\n" + response.body
        end
      else
        warn "delete_objects passed a bogus results hash, #{result_name} has no id field"
      end
    end
    successcount
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
    data['updated_at'] = Time.now.strftime("%Y-%m-%d %H:%M:%S")
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

    cpu_percent = getcpupercent
    login_count = getlogincount
    disk_usage = getdiskusage
    # have to round it up because server code only takes integer 
    data['utilization_metric[percent_cpu][value]'] = cpu_percent.round if cpu_percent
    data['utilization_metric[login_count][value]'] = login_count if login_count
    data['used_space'] = disk_usage[:used_space] if disk_usage
    data['avail_space'] = disk_usage[:avail_space] if disk_usage
    getvolumes.each do |key, value|
      data[key] = value
    end

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
      if processor =~ /(\S+)\s(.+)/
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

    data['uniqueid'] = get_uniqueid

    # TODO: figure out list of guests if it's a host
    vmstatus = getvmstatus
    if vmstatus == 'xenu'
      data['virtualmode'] = 'guest'
      data['virtualarch'] = 'xen'
    elsif vmstatus == 'xen0'
      data['virtualmode'] = 'host'
      data['virtualarch'] = 'xen'
    elsif vmstatus == 'vmware_server'
      data['virtualmode'] = 'host'
      data['virtualarch'] = 'vmware'
    elsif vmstatus == 'vmware'
      data['virtualmode'] = 'guest'
      data['virtualarch'] = 'vmware'
    end

    if data['hardware_profile[model]'] == 'VMware Virtual Platform'
      getdata = {} 
      getdata[:objecttype] = 'nodes'
      getdata[:exactget] = {'virtual_client_ids' => [data['uniqueid']]}
      getdata[:login] = 'autoreg'
      results = get_objects(getdata)
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
      getdata = {} 
      getdata[:objecttype] = 'nodes'
      getdata[:exactget] = {'uniqueid' => [data['uniqueid']]}
      getdata[:login] = 'autoreg'
      results = get_objects(getdata)
    end

    # If we failed to find an existing entry based on the unique id
    # fall back to the hostname.  This may still fail to find an entry,
    # if this is a new host, but that's OK as it will leave %results
    # as undef, which triggers set_nodes to create a new entry on the
    # server.
    if !results && data['name']
      getdata = {} 
      getdata[:objecttype] = 'nodes'
      getdata[:exactget] = {'name' => [data['name']]}
      getdata[:login] = 'autoreg'
      results = get_objects(getdata)
    end

    setresults = set_objects('nodes', results, data, 'autoreg')
    puts "Command successful" if setresults == 1
  end

  # The first argument is a hash returned by a 'nodes' call to get_objects
  # The second argument is a hash returned by a 'node_groups'
  # call to get_objects
  # NOTE: For the node groups you must have requested that the server include 'nodes' in the result
  def add_nodes_to_nodegroups(nodes, nodegroups, login, password_callback=PasswordCallback)
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
      merged_nodes = nodes.clone
      nodegroup["nodes"].each do |node|
         name = node['name']
         merged_nodes[name] = node
      end
      set_nodegroup_node_assignments(merged_nodes, {nodegroup_name => nodegroup}, login, password_callback)
    end
  end
  # The first argument is a hash returned by a 'nodes' call to get_objects
  # The second argument is a hash returned by a 'node_groups'
  # call to get_objects
  # NOTE: For the node groups you must have requested that the server include 'nodes' in the result
  def remove_nodes_from_nodegroups(nodes, nodegroups, login, password_callback=PasswordCallback)
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

      nodegroup['nodes'].each do |node|
        name = node['name']
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
  def set_nodegroup_node_assignments(nodes, nodegroups, login, password_callback=PasswordCallback)
    node_ids = []
    nodes.each_pair do |node_name, node|
      if node['id']
        node_ids << node['id']
      else
        warn "set_nodegroup_node_assignments passed a bogus nodes hash, #{node_name} has no id field"
      end
    end

    nodegroupdata = {}
    node_ids = 'nil' if node_ids.empty?
    nodegroupdata['node_group_node_assignments[nodes][]'] = node_ids

    set_objects('node_groups', nodegroups, nodegroupdata, login, password_callback)
  end

  # Both arguments are hashes returned by a 'node_groups' call to get_objects
  # NOTE: For the parent groups you must have requested that the server include 'child_groups' in the result
  def add_nodegroups_to_nodegroups(child_groups, parent_groups, login, password_callback=PasswordCallback)
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

      if parent_group[child_groups]
        parent_group[child_groups].each do |child_group|
          name = child_group[name]
          merged_nodegroups[name] = child_group
        end
      end

      set_nodegroup_nodegroup_assignments(merged_nodegroups, {parent_group_name => parent_group}, login, password_callback)
    end
  end
  # Both arguments are hashes returned by a 'node_groups' call to get_objects
  # NOTE: For the parent groups you must have requested that the server include 'child_groups' in the result
  def remove_nodegroups_from_nodegroups(child_groups, parent_groups, login, password_callback=PasswordCallback)
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
      if parent_groups[child_groups]
        parent_group[child_groups].each do |child_group|
          name = child_group[name]
          if !child_groups.has_key?(name)
            desired_child_groups[name] = child_group
          end
        end
      end

      set_nodegroup_nodegroup_assignments(desired_child_groups, {parent_group_name => parent_group}, login, password_callback)
    end
  end
  # Both arguments are hashes returned by a 'node_groups' call to get_objects
  def set_nodegroup_nodegroup_assignments(child_groups, parent_groups, login, password_callback=PasswordCallback)
    child_ids = []
    child_groups.each_pair do |child_group_name, child_group|
      if child_group['id']
        child_ids << child_group['id']
      else
        warn "set_nodegroup_nodegroup_assignments passed a bogus child groups hash, #{child_group_name} has no id field"
      end
    end
    # cannot pass empty hash therefore, add a 'nil' string. nasty hack and accomodated on the server side code
    child_ids << 'nil' if child_ids.empty?
    nodegroupdata = {}
    nodegroupdata['node_group_node_group_assignments[child_groups][]'] = child_ids
    set_objects('node_groups', parent_groups, nodegroupdata, login, password_callback)
  end
  
  #
  # Private methods
  #
  private

  def make_http(uri)
    http = nil
    if @proxy_server
      proxyuri = URI.parse(@proxy_server)
      proxy = Net::HTTP::Proxy(proxyuri.host, proxyuri.port)
      http = proxy.new(uri.host, uri.port)
    else
      http = Net::HTTP.new(uri.host, uri.port)
    end
    if uri.scheme == "https"
      # Eliminate the OpenSSL "using default DH parameters" warning
      if File.exist?(@dhparams)
        dh = OpenSSL::PKey::DH.new(IO.read(@dhparams))
        Net::HTTP.ssl_context_accessor(:tmp_dh_callback)
        http.tmp_dh_callback = proc { dh }
      end
      http.use_ssl = true
      if @ca_file && File.exist?(@ca_file)
        http.ca_file = @ca_file
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      end 
      if @ca_path && File.directory?(@ca_path)
        http.ca_path = @ca_path
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      end
    end
    http
  end
  
  # Returns the path to the cookiefile to be used. 
  # Create the file and correct permissions on
  # the cookiefile if needed
  def get_cookiefile(login=nil)
    # autoreg has a special file
    if login == 'autoreg'
      @cookiefile = '/root/.nventory_cookie_autoreg'
      if ! File.directory?('/root')
        Dir.mkdir('/root')
      end
    end
    # Create the cookie file if it doesn't already exist
    if !File.exist?(@cookiefile)
      warn "Creating #{@cookiefile}"
      File.open(@cookiefile, 'w') { |file| }
    end
    # Ensure the permissions on the cookie file are appropriate,
    # as it will contain a session key that could be used by others
    # to impersonate this user to the server.
    st = File.stat(@cookiefile)
    if st.mode & 07177 != 0
      warn "Correcting permissions on #{@cookiefile}"
      File.chmod(st.mode & 0600, @cookiefile)
    end
    @cookiefile
  end
  
  # Sigh, Ruby doesn't have a library for handling a persistent
  # cookie store so we have to do the dirty work ourselves.  This
  # is by no means a full implementation, it's just enough to do
  # what's needed here.

  # Break's a Set-Cookie line up into its constituent parts
  # Example from http://en.wikipedia.org/wiki/HTTP_cookie:
  # Set-Cookie: RMID=732423sdfs73242; expires=Fri, 31-Dec-2010 23:59:59 GMT; path=/; domain=.example.net
  def parse_cookie(line)
    cookie = nil
    if line =~ /^Set-Cookie\d?: .+=.+/
      cookie = {}
      line.chomp!
      cookie[:line] = line
      # Remove the Set-Cookie portion of the line
      setcookie, rest = line.split(' ', 2)
      # Then break off the name and value from the cookie attributes
      namevalue, rawattributes = rest.split('; ', 2)
      name, value = namevalue.split('=', 2)
      cookie[:name] = name
      cookie[:value] = value
      attributes = {}
      rawattributes.split('; ').each do |attribute|
        attrname, attrvalue = attribute.split('=', 2)
        # The Perl cookie jar uses a non-standard syntax, which seems to
        # include wrapping some fields (particularly path) in quotes.  The
        # Perl nVentory library uses the Perl cookie jar code so we need to be
        # compatible with it.
        if attrvalue =~ /^".*"$/
          attrvalue.sub!(/^"/, '')
          attrvalue.sub!(/"$/, '')
        end
        # rfc2965, 3.2.2:
        # If an attribute appears more than once in a cookie, the client
        # SHALL use only the value associated with the first appearance of
        # the attribute; a client MUST ignore values after the first.
        if !attributes[attrname]
          attributes[attrname] = attrvalue
        end
      end
      cookie[:attributes] = attributes
    else
      # Invalid lines in the form of comments and blank lines are to be
      # expected when we're called by read_cookiefile, so don't treat this as
      # a big deal.
      puts "parse_cookie passed invalid line: #{line}" if (@debug)
    end
    cookie
  end
  
  # Returns an array of cookies from the specified cookiefile
  def read_cookiefile(cookiefile)
    warn "Using cookies from #{cookiefile}" if (@debug)
    cookies = []
    IO.foreach(cookiefile) do |line|
      cookie = parse_cookie(line)
      if cookie && cookie[:attributes] && cookie[:attributes]["expires"]
        if DateTime.parse(cookie[:attributes]["expires"]) < DateTime.now
          warn "Cookie expired: #{cookie[:line]}" if @debug
          next
        end
      end
      if cookie
        cookies << cookie
      end
    end
    cookies
  end
  
  # This returns any cookies in the cookiefile which have domain and path
  # settings that match the specified uri.
  def get_cookies_for_uri(cookiefile, uri)
    cookies = []
    latest_cookie = []
    counter = 0
    read_cookiefile(cookiefile).each do |cookie|
      next unless uri.host =~ Regexp.new("#{cookie[:attributes]['domain']}$")
      next unless uri.path =~ Regexp.new("^#{cookie[:attributes]['path'].gsub(/,.*/,'')}") # gsub in case didn't parse out comma seperator for new cookie
      # if there are more than 1 cookie , we only want the one w/ latest expiration
      if cookie[:attributes]["expires"]
        unless latest_cookie.empty?
          cookie_expiration = DateTime.parse(cookie[:attributes]["expires"])
          latest_cookie[0] < cookie_expiration ? (latest_cookie = [cookie_expiration, cookie]) : next
        else
          latest_cookie = [ DateTime.parse(cookie[:attributes]["expires"]), cookie ]
        end
      else
        cookies << cookie
      end
    end
    cookies << latest_cookie[1] unless latest_cookie.empty?
    cookies
  end
  
  # Extract cookie from response and save it to the user's cookie store
  def extract_cookie(response, uri, login=nil)
    if response['set-cookie']
      cookiefile = get_cookiefile(login)
      # It doesn't look like it matters for our purposes at the moment, but
      # according to rfc2965, 3.2.2 the Set-Cookie header can contain more
      # than one cookie, separated by commas.
      puts "extract_cookie processing #{response['set-cookie']}" if (@debug)
      newcookie = parse_cookie('Set-Cookie: ' + response['set-cookie'])
      return if newcookie.nil?

      # Some cookie fields are optional, and should default to the
      # values in the request.  We need to insert these so that we
      # save them properly.
      # http://cgi.netscape.com/newsref/std/cookie_spec.html
      if !newcookie[:attributes]['domain']
        puts "Adding domain #{uri.host} to cookie" if (@debug)
        newcookie = parse_cookie(newcookie[:line] + "; domain=#{uri.host}")
      end
      if !newcookie[:attributes]['path']
        puts "Adding path #{uri.path} to cookie" if (@debug)
        newcookie = parse_cookie(newcookie[:line] + "; path=#{uri.path}")
      end
      cookies = []
      change = false
      existing_cookie = false
      read_cookiefile(cookiefile).each do |cookie|
        # Remove any existing cookies with the same name, domain and path
        puts "Comparing #{cookie.inspect} to #{newcookie.inspect}" if (@debug)
        if cookie[:name] == newcookie[:name] &&
           cookie[:attributes]['domain'] == newcookie[:attributes]['domain'] &&
           cookie[:attributes]['path'] == newcookie[:attributes]['path']
          existing_cookie = true
          if cookie == newcookie
            puts "Existing cookie is identical to new cookie" if (@debug)
          else
            # Cookie removed by virtue of us not saving it here
            puts "Replacing existing but not identical cookie #{cookie.inspect}" if (@debug)
            cookies << newcookie
            change = true
          end
        else
          puts "Keeping non-matching cookie #{cookie.inspect}" if (@debug)
          cookies << cookie
        end
      end
      if !existing_cookie
        puts "No existing cookie matching new cookie, adding new cookie" if (@debug)
        cookies << newcookie
        change = true
      end
      if change
        puts "Updating cookiefile #{cookiefile}" if (@debug)
        File.open(cookiefile, 'w') { |file| file.puts(cookies.collect{|cookie| cookie[:line]}.join("\n")) }
      else
        puts "No cookie changes, leaving cookiefile untouched" if (@debug)
      end
    else
      puts "extract_cookie finds no cookie in response" if (@debug)
    end
  end
  
  # Sends requests to the nVentory server and handles any redirects to
  # authentication pages or services.
  def send_request(req, uri, login, password_callback=PasswordCallback,loopcounter=0,stopflag=false)
    if loopcounter > 7
      if stopflag
        raise "Infinite loop detected"
      else
        warn "Loop detected.  Clearing out cookiefile.."
        loopcounter = 0
        stopflag = true
        File.open(get_cookiefile(login), 'w') { |file| file.write(nil) }
      end
    end
    cookies = get_cookies_for_uri(get_cookiefile(login), uri)
    if !cookies.empty?
      cookiestring = cookies.collect{|cookie| "#{cookie[:name]}=#{cookie[:value]}" }.join('; ')
      puts "Inserting cookies into request: #{cookiestring}" if (@debug)
      req['Cookie'] = cookiestring
    end
    
    response = make_http(uri).request(req)
    extract_cookie(response, uri, login)
    
    # Check for signs that the server wants us to authenticate
    password = nil
    if login == 'autoreg'
      password = 'mypassword'
    end
    # nVentory will redirect to the login controller if authentication is
    # required.  The scheme and port in the redirect location could be either
    # the standard server or the https variant, depending on whether or not
    # the server administration has turned on the ssl_requirement plugin.
    if response.kind_of?(Net::HTTPFound) &&
       response['Location'] &&
       URI.parse(response['Location']).host == URI.parse(@server).host &&
       URI.parse(response['Location']).path == URI.join(@server, 'login/login').path
      puts "Server responsed with redirect to nVentory login: #{response['Location']}" if (@debug)
      loginuri = URI.parse(response['Location'])
      ####################### Fix by darrendao - force it to use https ##########################
      # This is needed because if you're not usign https, then you will get 
      # redirected to https login page, rather than being logged in. So the check down there will
      # will.
      loginuri.scheme = 'https'
      loginuri = URI.parse(loginuri.to_s)
      ############################################################################################
      loginreq = Net::HTTP::Post.new(loginuri.request_uri)
      if password_callback.kind_of?(Module)
        password = password_callback.get_password if (!password)
      else
        password = password_callback if !password
      end
      loginreq.set_form_data({'login' => login, 'password' => password})
      # Include the cookies so the server doesn't have to generate another
      # session for us.
      loginreq['Cookie'] = cookiestring
      loginresponse = make_http(loginuri).request(loginreq)
      if @debug
        puts "nVentory auth POST response (#{loginresponse.code}):"
        if loginresponse.body.strip.empty?
          puts '<Body empty>'
        else
          puts loginresponse.body
        end
      end
      # The server always sends back a 302 redirect in response to a login
      # attempt.  You get redirected back to the login page if your login
      # failed, or redirected to your original page or the main page if the
      # login succeeded.
      if loginresponse.kind_of?(Net::HTTPFound) &&
         URI.parse(loginresponse['Location']).path != loginuri.path
        puts "Authentication against nVentory server succeeded" if (@debug)
        extract_cookie(loginresponse, loginuri, login)
        puts "Resending original request now that we've authenticated" if (@debug)
        return send_request(req, uri, login, password_callback)
      else
        puts "Authentication against nVentory server failed" if (@debug)
      end
    end
    
    # An SSO-enabled app will redirect to SSO if authentication is required
    if response.kind_of?(Net::HTTPFound) &&
       response['Location'] &&
       URI.parse(response['Location']).host == URI.parse(@sso_server).host
      puts "Server responsed with redirect to SSO login: #{response['Location']}" if (@debug)
      if login == 'autoreg'
        loginuri = URI.join(@server, 'login/login')
        puts "** Login user is 'autoreg'.  Changing loginuri to #{loginuri.to_s}" if @debug
        unless loginuri.scheme == 'https'
          loginuri.scheme = 'https'
          loginuri = URI.parse(loginuri.to_s)
        end
      else
        loginuri = URI.parse(response['Location'])
      end
      loginreq = Net::HTTP::Post.new(loginuri.request_uri)
      if password_callback.kind_of?(Module)
        password = password_callback.get_password if (!password)
      else
        password = password_callback if !password
      end
      loginreq.set_form_data({'login' => login, 'password' => password})
      # It probably doesn't matter, but include the cookies again for good
      # measure
      loginreq['Cookie'] = cookiestring
      # Telling the SSO server we want XML back gets responses that are easier
      # to parse.
      loginreq['Accept'] = 'application/xml'
      loginresponse = make_http(loginuri).request(loginreq)

      # if it's a redirect (such as due to NON-fqdn) loop so that it follows until no further redirect
      while loginresponse.kind_of?(Net::HTTPMovedPermanently)
        puts "** Following redirect #{loginresponse.class.to_s} => #{loginresponse['Location'].to_s}" if @debug
        loginuri = URI.parse(loginresponse['Location'])
        loginreq = Net::HTTP::Post.new(loginuri.request_uri)
        loginreq.set_form_data({'login' => login, 'password' => password})
        loginresponse = make_http(loginuri).request(loginreq)
      end # while loginresponse.kind_of?(Net::HTTPMovedPermanently)

      if @debug
          puts "AUTH POST response (#{loginresponse.code}):"
          if loginresponse.body.strip.empty?
            puts '<Body empty>'
          else
            puts loginresponse.body
          end
      end

      # SSO does a number of redirects until you get to the right domain but should just follow once and get the cookie, will become Net::HTTPNotAcceptable (406). 
      if loginresponse.kind_of?(Net::HTTPFound) && loginresponse['Location'] =~ /sso.*\/session\/token.*.xml/
        puts "** Following redirect #{loginresponse.class.to_s} => #{loginresponse['Location'].to_s}" if @debug
        loginuri = URI.parse(loginresponse['Location'])
        loginreq = Net::HTTP::Get.new(loginuri.request_uri)
        loginresponse = make_http(loginuri).request(loginreq)
      end

      # some bug, but once sso gives you a token non-SSL url redirect, and you follow it, you get redirected to yet another URL that is SSL for a token again
      if loginresponse.kind_of?(Net::HTTPFound) && loginresponse['Location'] =~ /^https:\/\/sso.*\/session\/token.*.xml/
        puts "** Following redirect #{loginresponse.class.to_s} => #{loginresponse['Location'].to_s}" if @debug
        loginuri = URI.parse(loginresponse['Location'])
        loginreq = Net::HTTP::Get.new(loginuri.request_uri)
        loginresponse = make_http(loginuri).request(loginreq)
      end

      # The SSO server sends back 200 if authentication succeeds, 401 or 403
      # if it does not.
      if loginresponse.kind_of?(Net::HTTPSuccess) || (loginresponse.kind_of?(Net::HTTPFound) && loginresponse['Location'] =~ /^#{loginuri.scheme}:\/\/#{loginuri.host}\/$/ )  || loginresponse.kind_of?(Net::HTTPNotAcceptable)
        puts "Authentication against server succeeded" if (@debug)
        extract_cookie(loginresponse, loginuri, login)
        puts "Resending original request now that we've authenticated" if (@debug)
        loopcounter += 1
        return send_request(req, uri, login, password_callback, loopcounter,stopflag)
      else
        puts "Authentication against server failed" if (@debug)
      end
    end
    
    response
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

  def find_sar
    path_env = (ENV['PATH'] || "").split(':')
    other_paths = ["/usr/bin", "/data/svc/sysstat/bin"]
    sarname = 'sar'
    (path_env | other_paths).each do |path|
      if File.executable?(File.join(path, sarname))
        return File.join(path, sarname)
      end
    end
  end
  
  def get_sar_data(sar_dir=nil, day = nil)
    sar = find_sar
    result = []
    cmd  = nil
    ENV['LC_TIME']='POSIX'
    if day
      day = "0#{day}" if day < 10
      cmd = "#{sar} -u -f #{sar_dir}/sa#{day}"
    else
      cmd = "#{sar} -u"
    end
    output = `#{cmd}`
    output.split("\n").each do |line|
      result << line unless line =~ /(average|cpu|%|linux)/i
    end
    result
  end

  # I'm sure there's a better way to do all of these. However,
  # I'm just following the way the code was written in Perl. 
  def getcpupercent
    return if !Facter['kernel'] or Facter['kernel'].value != 'Linux'
    sar_dir = "/var/log/sa"
    end_time = Time.now
    start_time = end_time - 60*60*3
    end_date = end_time.strftime("%d")
    start_date = start_time.strftime("%d")

    data_points = []
    # all hours in same day so just make list of all hours to look for
    if end_date == start_date
      today_sar = get_sar_data
      return false if today_sar.empty? 

      # We only take avg of last 3 hours
      (start_time.hour..end_time.hour).each do | hour |
         hour = "0#{hour}" if hour < 10
         today_sar.each do |line|
           data_points << $1.to_f if line =~ /^#{hour}:.*\s(\S+)$/
         end
      end
    else
      today_sar = get_sar_data
      yesterday_sar = get_sar_data(sar_dir, start_date)
      return false if today_sar.empty? or yesterday_sar.empty?
      # Parse today sar data
      (0..end_time.hour).each do | hour |
         hour = "0#{hour}" if hour < 10
         today_sar.each do |line|
           data_points << $1.to_f if line =~ /^#{hour}:.*\s(\S+)$/
         end
      end
    
      # Parse yesterday sar data
      (start_time.hour..23).each do | hour |
         hour = "0#{hour}" if hour < 10
         yesterday_sar.each do |line|
           data_points << $1.to_f if line =~ /^#{hour}:.*\s(\S+)$/
         end
      end
    end

    avg = data_points.inject(0.0) { |sum, el| sum + el } / data_points.size
    # sar reports % idle, so need the opposite
    result = 100 - avg
    return result
  end

  # This is based on the perl version in OSInfo.pm
  def getlogincount

    # darrendao: Looks like this number has to match up with how often
    # nventory-client is run in the crontab, otherwise, nventory server ends up
    # miscalculating the sum... bad...
    # How many hours of data we need to sample, not to exceed 24h
    minus_hours = 3

    # get unix cmd 'last' content
    begin
      content = `last`
    rescue
      warn "Failed to run 'last' command"
      return nil
    end
    

    counter = 0

    (0..minus_hours).each do | minus_hour |
      target_time = Time.now - 60*60*minus_hour
      time_str = target_time.strftime("%b %d %H")
      content.split("\n").each do |line|
        counter += 1 if line =~ /#{time_str}/
      end 
    end
    return counter 
  end

  # This is based on the perl version in OSInfo.pm
  def getdiskusage
    content = ""
    begin
      content = `df -k`
    rescue
      warn "Failed to run df command"
      return nil
    end
    used_space = 0
    avail_space = 0
    content.split("\n").each do |line|
      if line =~ /\s+\d+\s+(\d+)\s+(\d+)\s+\d+%\s+\/($|home$)/
        used_space += $1.to_i
        avail_space += $2.to_i
      end
    end
    return {:avail_space => avail_space, :used_space => used_space}
  end

  def getvolumes
    return getmountedvolumes.merge(getservedvolumes)
  end

  # This is based on the perl version in OSInfo.pm
  def getservedvolumes
    # only support Linux for now
    return {} unless Facter['kernel'] && Facter['kernel'].value == 'Linux'

    # Don't do anything if exports file is not there
    return {} if !File.exists?("/etc/exports")

    served = {}

    IO.foreach("/etc/exports") do |line|
      if line =~ /(\S+)\s+/
        vol = $1
        served["volumes[served][#{vol}][config]"] = "/etc/exports"
        served["volumes[served][#{vol}][type]"] = 'nfs'
      end
    end
    return served
  end

  # This is based on the perl version in OSInfo.pm
  def getmountedvolumes
    # only support Linux for now
    return {} unless Facter['kernel'] && Facter['kernel'].value == 'Linux'
   
    dir = "/etc"
    mounted = {}
    
    # AUTOFS - gather only files named auto[._]*
    Dir.glob(File.join(dir, "*")).each do |file|
      next if file !~ /^auto[._].*/ 
      
      # AUTOFS - match only lines that look like nfs syntax such as host:/path
      IO.foreach(file) do |line|
        if  line =~ /\w:\S/  && line !~ /^\s*#/
          # Parse it, Example : " nventory_backup    -noatime,intr   irvnetappbk:/vol/nventory_backup "
          if line =~ /^(\w[\w\S]+)\s+\S+\s+(\w[\w\S]+):(\S+)/
            mnt = $1
            host = $2
            vol =  $3
            mounted["volumes[mounted][/mnt/#{mnt}][config]"] = file
            mounted["volumes[mounted][/mnt/#{mnt}][volume_server]"] = host
            mounted["volumes[mounted][/mnt/#{mnt}][volume]"] = vol
            mounted["volumes[mounted][/mnt/#{mnt}][type]"] = 'nfs'
          end
        end
      end  # IO.foreach
    end # Dir.glob

    # FSTAB - has diff syntax than AUTOFS.  Example: "server:/usr/local/pub    /pub   nfs    rsize=8192,wsize=8192,timeo=14,intr"   
    IO.foreach("/etc/fstab") do |line|
      if line =~ /^(\w[\w\S]+):(\S+)\s+(\S+)\s+nfs/ 
        host = $1
        vol = $2
        mnt = $3
        mounted["volumes[mounted][#{mnt}][config]"] = "/etc/fstab"
        mounted["volumes[mounted][#{mnt}][volume_server]"] = host
        mounted["volumes[mounted][#{mnt}][volume]"] = vol
        mounted["volumes[mounted][#{mnt}][type]"] = 'nfs'
      end
    end # IO.foreach
    return mounted  
  end

  def getvmstatus
    # facter virtual makes calls to commands that are under /sbin
    ENV['PATH'] = "#{ENV['PATH']}:/sbin"
    vmstatus = `facter virtual`
    vmstatus.chomp!
  end

  def get_uniqueid
    os = Facter['kernel'].value 
    if os == 'Linux' or os == 'FreeBSD'
      # best to use UUID from dmidecode
      uuid = getuuid
      if uuid
        uniqueid = uuid
      # next best thing to use is macaddress
      else
        uniqueid = Facter['macaddress'].value
      end 
    elsif Facter['uniqueid'] && Facter['uniqueid'].value
      # This sucks, it's just using hostid, which is generally tied to an
      # IP address, not the physical hardware
      uniqueid = Facter['uniqueid'].value
    elsif Facter['sp_serial_number'] && Facter['sp_serial_number'].value
      # I imagine Mac serial numbers are unique
      uniqueid = Facter['sp_serial_number'].value
    end
    return uniqueid
  end
  
  def getuuid
    uuid = nil
    # dmidecode will fail if not run as root
    if Process.euid != 0 
      raise "This must be run as root"
    end
    uuid_entry = `/usr/sbin/dmidecode  | grep UUID`
    if uuid_entry
      uuid = uuid_entry.split(":")[1]
    end
    return uuid.strip
  end
end
