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

  def export_serverir
    line = ['Server Name', 'ITDR State', 'Logical Resource Name', 'Logical Resource Type', 'Service', 'Purpose', 'Operating Mode', 'Site', 'Site Type', 'OS Class', 'OS Version', 'CPU Capacity', 'Memory', 'Base Power', 'Power Increment', 'Rack Unit Equivalents', 'Vendor', 'Model', 'Processor Family', 'Clock Speed', 'Number of Processors', 'Number of Cores', 'Number of Logical CPUs', 'L2 Cache', 'L3 Cache', 'Collector', 'Configuration Collector', 'Description', 'Serial Number', 'VM Architecture', 'VM Mode', "\n"]
    csvdoc = [line.join(',')]
    Node.all.each do |node|
      results = make_line(node)
      csvdoc << results.join(',') if results
    end
    fname = "public/csvexports/#{Time.now.strftime("%d%m%Y-%H:00")}.gz"
    File.open(fname, 'w') do |f|
      gz = Zlib::GzipWriter.new(f)
      gz.write csvdoc
      gz.close
    end
  end

  private
  def make_line(node)
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
    line << 'nVentory'
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
end
