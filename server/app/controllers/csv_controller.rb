class CsvController < ApplicationController
  before_filter :get_obj_auth
  before_filter :modelperms

  def export
    @csvparams = session[:csvobj]
    @csvparams[:attributes] = params[:attributes]
    @csvparams[:username] = current_user.login
    CsvWorker.async_sendata(:csvparams => @csvparams)
    respond_to do |format|
      format.html
    end
  end

  # serverir is something written up to export data to AT&T IS Accounting dept (david kaufman).  never has been put to use  def export_serverir
  def export_serverir
    line = ['Server Name', 'ITDR State', 'Logical Resource Name', 'Logical Resource Type', 'Service', 'Purpose', 'Operating Mode', 'Site', 'Site Type', 'OS Class', 'OS Version', 'CPU Capacity', 'Memory', 'Base Power', 'Power Increment', 'Rack Unit Equivalents', 'Vendor', 'Model', 'Processor Family', 'Clock Speed', 'Number of Processors', 'Number of Cores', 'Number of Logical CPUs', 'L2 Cache', 'L3 Cache', 'Collector', 'Configuration Collector', 'Description', 'Serial Number', 'VM Architecture', 'VM Mode', "\n"]
    csvdoc = [line.join(',')]
    Node.all.each do |node|
      results = make_serverir_line(node)
      csvdoc << results.join(',') if results
    end
    fname = "public/csvexports/#{Time.now.strftime("%d%m%Y-%H:00")}.gz"
    File.open(fname, 'w') do |f|
      gz = Zlib::GzipWriter.new(f)
      gz.write csvdoc
      gz.close
    end
  end

  # cso feed for inventory tracking 
  def export_csofeed
    # Create header row #
    header = ['Record Type', 'Device Key', 'IP Addresses', 'MAC Addresses', 'System Name', 'FQDN', 'Status', 'Function', 'Runs MOTS/PRISM Apps', 'MOTS/PRISM IDs', 'Runs Non-MOTS/PRISM Apps', 'Internet Facing', 'Device Criticality', 'Device Owner', 'Operating System', 'Operating System Version', 'Administrator\'s ATTUID', 'Support Group', 'Serial Number', 'Asset Tag Number', 'Location', 'Location CLLI', 'Comments' "\n"]
    csvdoc = [header.join(',')]
    Node.all.each do |node|
      result = make_csoline(node)
      csvdoc << result.join(',') if result
   end
    fname = "public/csvexports/csofeed_#{Time.now.strftime("%d%m%Y")}.csv.gz"
    File.open(fname, 'w') do |f|
      gz = Zlib::GzipWriter.new(f)
      gz.write csvdoc
      gz.close
    end
  end

  private
  def make_serverir_line(node)
    line = []
    line << node.name # server name
    line << node.status.name  # ITDR STATE - aka status
    line << nil # logical resource name
    line << nil # logical resource type
    line << node.node_groups.collect(&:name).join(':') # service
    line << node.node_groups.collect(&:name).join(':') # purpose
    tags = []
    node.node_groups.each do |ng|
      tags << ng.name if ng.tags.include?('environment')
    end
    tags.empty? ? ( line << nil ) : ( line << tags.join(':') ) # 7) operating_mode
    if node.node_rack && node.node_rack.datacenter
      line << node.node_rack.datacenter.name # site location
    else
      line << nil
    end
    line << nil # site type
    if node.operating_system
      # 9) os class
      if node.operating_system.name =~ /windows/i
        line << 'windows'
      elsif node.operating_system.name =~ /linux/i
        line << 'linux'
      else
        line << nil
      end
      line << node.operating_system.name.gsub(/,/,"") # 10) os version
    else
      line << nil
      line << nil
    end
    line << nil # os cpu capacity
    line << node.physical_memory # memory
    line << nil # power 
    line << nil # power increment
    line << node.hardware_profile.rack_size # rack unit size
    line << node.hardware_profile.name.gsub(/,/,"").match(/\S+/).to_s
    if node.hardware_profile.model
      line << node.hardware_profile.model.gsub(/,/,"")
    else
      nil
    end
    if node.processor_model
      line << node.processor_model.gsub(/,/,"")
    else
      line << nil
    end
    clockspd = node.processor_speed
    if clockspd =~ /ghz/i
      ghz_to_mhz = clockspd.match(/[\d\.]+/).to_s.to_f * 1000
      line << ghz_to_mhz.to_i
    elsif clockspd =~ /mhz/i
      line << clockspd.match(/\d+/).to_s
    else
      line << 'Unknown'
    end
    line << node.processor_count
    line << node.processor_count
    line << nil
    line << nil
    line << nil
    line << 'OpsDB'
    line << nil
    line << node.hardware_profile.description
    if node.serial_number
      line << node.serial_number.match(/\S+/)
    else
      line << nil
    end
    line << node.virtualarch
    if node.virtualarch
      if node.virtual_host
        line << 'vmguest'
      elsif node.virtual_guests
        line << 'vmhost'
      end
    end
    line << "\n"
  end

  def submake_csoline(node,mac_addr=nil,ipaddr=nil)
    line = []
    fqdn = node.name
    # 1) RECORD TYPE - the first line for a node is labelled 'primary'; every line thereafter is 'secondary' #
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
    if status == 'inservice'
      line << 'active'
    elsif status == 'available'
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
    line << "\n"
    return line
  end

  def make_csoline(node)
    results = nil
    # The number of csv rows/lines per node depend on how many ip_addresses/mac_addresses (nics) it has #
    if node.network_interfaces.size < 1
      results = submake_csoline(node,nil,nil)
    else
      eths = []
      eth_hash = {}
      # Ensure NIC is ethernet otherwise skip
      node.network_interfaces.each { |nic| (eths << nic) if (nic.interface_type == 'Ethernet') }
      if eths.size >= 1
        eths.each do |eth|
          # IP ADDRESSES - each nic may have more than one IP, check to see if ipv4 before recording #
          eth_hash[eth.hardware_address] = []
          eth.ip_addresses.each do |ipaddr|
              ((eth_hash[eth.hardware_address] << ipaddr.address) unless ipaddr =~ /(127\.0\.0\.1|0\.0\.0\.0)/) if ipaddr.address_type == 'ipv4'
          end
        end
      end
  
      eth_hash.each_pair do |mac_addr,ip_addresses|
        if ip_addresses.size >= 1
          ip_addresses.each do |ipaddr|
            results = submake_csoline(node,mac_addr,ipaddr)
          end # ip_addresses.each do |ipaddr|
        else
          results = submake_csoline(node,mac_addr,nil)
        end
      end # eth_hash.each_pair do |mac_addr,ip_addresses|
    end  # if node.network_interfaces.size < 1
    return results
  end

end
