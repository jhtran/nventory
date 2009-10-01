class JobsController < ApplicationController

  def make_fields(node,mac_addr,ipaddr)
    line = []
    if @x == true
      fqdn = node.name
      # 1) RECORD TYPE - the first line for a node is labelled 'primary'; every line thereafter is 'secondary' 
      line << 'primary'
      # 2) DEVICE KEY - unique id #
      line << node.uniqueid
      # 3) IP ADDRESS #
      (ipaddr.nil? || (ipaddr =~ /(127\.0\.0\.1|0\.0\.0\.0)/)) ? (return nil) : (line << ipaddr)
      # 4) MAC ADDRESS #
      (mac_addr.nil? || (mac_addr !~ /((?:(\d{1,2}|[a-fA-F]{1,2}){2})(?::|-*)){6}/)) ? (return nil) : (line << mac_addr)
      # 5) SYSTEM NAME #
      match = fqdn.match(/(\S+?)\./)
      unless match.nil?
        line << match[1]
      else
        fqdn.nil? ? (return nil) : (line << fqdn)
      end
      # 6) FQDN #
      fqdn.nil? ? (return nil) : (line << fqdn)
      # 7) STATUS
      #["inservice", "available", "broken", "setup", "outofservice", "prebuild", "reserved"]
      status = node.status.name
      if status.match(/inservice/i)
        line << 'active'
      elsif status.match(/available/i)
        line << status
      elsif status.match(/(broken|reserved|vmrequest)/i)
        line << 'bench'
      elsif status.match(/(setup|prebuild)/i)
        line << 'install'
      elsif status.match(/(outofservice|retired)/i)
        line << 'decommissioned'
      elsif status.nil?
        line << 'install'
      else
        line << 'install'
      end
      # 8) FUNCTION
      ## Only report 'Unknown' for now, until we get the node groups standardized
      #node_groups = []
      #(node/:node_group).each do |node_group|
      #  node_groups << (node_group/:name).innerHTML
      #end
      #if node_groups.size <= 1 
      #  line << node_groups.flatten
      #else
      #  line << "\"#{node_groups.join(',')}\""
      #end
      line << 'Unknown'
      # 9) RUNS MOTS/PRISM APPS
      line << 'NO'
      # 10) MOTS/PRISM ID's #
      line << nil
      # 11) RUNS NON-MOTS/PRISM APPS
      line << 'YES'
      # 12) INTERNET FACING
      line << 'YES'
      # 13) DEVICE CRITICALITY #
      line << 'YES'
      ## Report all as 'NO' for now, until a more consistent way of detecting
      #if fqdn =~ /prod/i
      #  line << 'YES'
      #elsif fqdn =~ /(stg|stag|dev|qa)/i
      #  line << 'NO'
      #else
      #  line << 'NO'
      #end
      # 14) DEVICE OWNER
      line << 'AT&T Interactive'
      # 15) OS #
      ## Restricted to 20 chars #
      os = node.operating_system.name.gsub(',',"")
      os.nil? ? (line << 'Unknown') : (line << os.match(/.{1,20}/))
      # 16) OS VERSION #
      osver = node.operating_system.version_number.gsub(',',' ')
      if (osver.nil? || osver.empty?)
        (os.nil? || os.empty?) ? (line << 'Unknown') : (line << os.match(/.{1,20}/))
      else
        line << osver.match(/.{1,20}/)
      end
      # 17) ADMIN attuid - ssinger if windows else syi #
      if os =~ /window/i
        admin_attuid = 'ss6371'
      elsif os =~ /(linux|unix|sunos)/i
        admin_attuid = 'sy976w'
      else
        admin_attuid = 'sys976w'
      end
      line << admin_attuid
      # 18) SUPPORT GROUP
      os =~ /windows/i ? support_group = ' Windows Admins' : support_group = ' Unix Admins'
      line << support_group
      # 19) SERIAL NUMBER
      line << node.serial_number.match(/\S+{1,20}/)
      # 20) ASSET TAG #
      line << nil
      # 21) LOCATION
      if ( node.node_rack && node.node_rack.datacenter )
        location = node.node_rack.datacenter.name
      end
      (location.nil? || location.empty?) ? (line << 'Unknown') : (line << location)
      # 22) LOCATION CLLI
      line << nil
      # 23) COMMENTS
      line << nil
      line << "\n"
      @x = false
    else
      # 1) row consists of secondary ip and or mac for nodes
      line << 'secondary'
      # 2) not needed in secondary rows
      line << nil
      # 3) IP ADDRESS - each nic may have more than one IP, check to see if ipv4 before recording #
      (ipaddr.nil? || (ipaddr =~ /(127\.0\.0\.1|0\.0\.0\.0)/)) ? (return nil) : (line << ipaddr)
      # 4) MAC ADDRESS #
(mac_addr.nil? || (mac_addr !~ /((?:(\d{1,2}|[a-fA-F]{1,2}){2})(?::|-*)){6}/)) ? (return nil) : (line << mac_addr)
      # 5)->11) not needed in secondary rows
      counter = 19
      while counter > 0
        line << nil
        counter -= 1
      end
      line << "\n"
      @x = false
    end # if @x == true
    return line
  end # def make_fields

  def cso_feed
    csvdoc = []
    all_objs = get_all_node_objects
    
    # Create header row #
    header = ['Record Type', 'Device Key', 'IP Addresses', 'MAC Addresses', 'System Name', 'FQDN', 'Status', 'Function', 'Runs MOTS/PRISM Apps', 'MOTS/PRISM IDs', 'Runs Non-MOTS/PRISM Apps', 'Internet Facing', 'Device Criticality', 'Device Owner', 'Operating System', 'Operating System Version', 'Administrator\'s  UID', 'Support Group', 'Serial Number', 'Asset Tag Number', 'Location', 'Location CLLI', 'Comments' "\n"]
    csvdoc << header.join(',')
    
    all_objs.each do |node|
      # The number of csv rows/lines per node depend on how many ip_addresses/mac_addresses (nics) it has #
      @x = true
      if node.network_interfaces.size < 1
        results = make_fields(node,nil,nil)
        csvdoc << results.join(',') unless results.nil?
      else
        eths = []
        node.network_interfaces.each do |nic|
          # Ensure NIC is ethernet otherwise skip
          unless nic.hardware_address.nil?
            eths << nic
          end
        end
    
        eth_hash = {}
        if eths.size >= 1 
          eths.each do |eth|
            # MAC ADDRESS #
            mac_addr = eth.hardware_address
            eth_hash[mac_addr] = []
            # IP ADDRESSES - each nic may have more than one IP, check to see if ipv4 before recording #
            eth.ip_addresses.each do |ipaddr|
              if ipaddr.address_type == 'ipv4'
                eth_hash[mac_addr] << ipaddr.address
              end
            end
          end
        end
    
        eth_hash.each_pair do |mac_addr,ip_addresses|
          if ip_addresses.size >= 1
            ip_addresses.each do |ipaddr|
              results = make_fields(node,mac_addr,ipaddr)
              csvdoc << results.join(',') unless results.nil?
            end # ip_addresses.each do |ipaddr|
          else
            results = make_fields(node,mac_addr,nil)
            csvdoc << results.join(',') unless results.nil?
          end
        end # eth_hash.each_pair do |mac_addr,ip_addresses|
      end # if (node/:network_interfaces).size < 1
    end  #(xmldoc/:node).each do |node|
    print csvdoc

  end # def cso_feed

  def get_all_node_objects
    # The default display index_row columns
    default_includes = [:operating_system, :hardware_profile, :node_groups, :status]
    special_joins = {
      'preferred_operating_system' =>
        'LEFT OUTER JOIN operating_systems AS preferred_operating_systems ON nodes.preferred_operating_system_id = preferred_operating_systems.id'
    }

    ## BUILD MASTER HASH WITH ALL SUB-PARAMS ##
    allparams = {}
    allparams[:mainmodel] = Node
    allparams[:webparams] = {:format => 'xml' }
    allparams[:default_includes] = default_includes
    allparams[:special_joins] = special_joins

    results = SearchController.new.search(allparams)
    includes = results[:includes]
    @objects = results[:search_results]
    return @objects
  end

end
