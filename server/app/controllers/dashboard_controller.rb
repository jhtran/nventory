class DashboardController < ApplicationController
  before_filter :getauth
  before_filter :modelperms

  def index
    UtilizationMetricsGlobal.last.nil? ? @percent_cpu_node_count = 0 : @percent_cpu_node_count = UtilizationMetricsGlobal.last.node_count.to_i
    respond_to do |format|
      format.html {
        @nodes_over_time_chart = open_flash_chart_object(500,300, url_for( :action => 'index', :graph => 'nodes_over_time_chart', :format => :json ))
        @operating_systems_pie = open_flash_chart_object(500,300, url_for( :action => 'index', :graph => 'operating_systems_pie', :format => :json ))
        @hardware_profiles_pie = open_flash_chart_object(700,400, url_for( :action => 'index', :graph => 'hardware_profiles_pie', :format => :json ))
        @global_cpu_percent_chart = open_flash_chart_object(500,300, url_for( :action => 'index', :graph => 'global_cpu_percent_chart', :format => :json ))        
      } # format.html
      format.json {
        case params[:graph]
          when 'nodes_over_time_chart'
            chart = nodes_over_time_chart_method
            render :text => chart.to_s
          when 'global_cpu_percent_chart'
            chart = global_cpu_percent_chart_method
            render :text => chart.to_s
          when 'hardware_profiles_pie'
            chart = hardware_profiles_pie_method
            render :text => chart.to_s
          when 'operating_systems_pie'
            chart = operating_systems_pie_method
            render :text => chart.to_s
        end
      } # format.json
    end
  end # def index

  def hardware_profiles_pie_method
    data = {}
    percent = {}
    pie_values = []
    other = 0
    HardwareProfile.find(:all, :include => {:nodes => {}}).each do |hwp|
      data[hwp.name] = hwp.nodes.size
    end
    sum = data.values.inject(0) { |s,v| s += v }
    unless sum == 0
      data.each_pair do |hwp,count|
        if (percent[(count * 100)/sum].nil?) || (percent[(count * 100)/sum].empty?) 
          percent[(count * 100)/sum] = [hwp]
        else
          percent[(count * 100)/sum] << hwp
        end
      end 
    end
    order = percent.keys.sort
    # only take the top 7 hw profiles otherwise pie graph is ugly
    counter = 15
    unless order.empty?
      while counter > 0
        highest_percent = order.pop
        # may be more than 1 hw profile with the same % key
        percent[highest_percent].each do |hwp|
          if counter > 0
            pie_values << PieValue.new(data[hwp], "#{hwp}: #{data[hwp]}")
            order.empty? ? (counter = 0) : (counter -= 1)
          else
            other += data[hwp]
          end
        end
      end # while counter > 0
    end
    # Doesn't matter what the OS's are left, we'll just add the # of those hwprofiles to "other"
    order.each do |leftover|
      other += leftover
    end
    pie_values << PieValue.new(other, "Other: #{other}")

    # Generate the graph
    title = Title.new("Members of Each Hardware Profile")
    title.set_style('{font-size: 20px; color: #778877}')
    pie = Pie.new
    pie.start_angle = 0
    pie.animate = true
    pie.values = pie_values
    chart = OpenFlashChart.new
    chart.title = title
    chart.add_element(pie)
    chart.bg_colour = '#FFFFFF'
    chart.x_axis = nil
    
    return chart
  end # def hardware_profiles_pie

  def nodes_over_time_chart_method
    data = {}
    data[:values] = []
    vmdata = {}
    vmdata[:values] = []
    months = []

    # Create datapoints for the past 12 months and keep them in array so that their order is retained
    counter = 12
    while counter >= 0
      month = counter.months.ago.month
      lastmonth = (counter+1).months.ago.month
      year = counter.months.ago.year
      months << "#{Date::ABBR_MONTHNAMES[lastmonth]}\n#{year}"
      date = Date.new(year,month)
      data[:values] << Node.count(:all,:include => {:virtual_host => {}},
                                  :conditions => ["nodes.created_at < ? and (virtual_assignments.parent_id is null or virtual_assignments.parent_id = '')", date.to_s(:db)])
      vmdata[:values] << Node.count(:all,:include => {:virtual_host => {}},
                                  :conditions => ["nodes.created_at < ? and (virtual_assignments.parent_id is not null and virtual_assignments.parent_id != '')", date.to_s(:db)])
      counter -= 1
    end

    # Create Graph
    title = Title.new("Nodes Over Time")
    title.set_style('{font-size: 20px; color: #778877}')
    line = Line.new
    line.text = "Real Nodes"
    line.set_values(data[:values])
    vmline = Line.new
    vmline.text = "VM Nodes"
    vmline.colour = '#FF0000'
    vmline.set_values(vmdata[:values])
    y = YAxis.new
    y.set_range(0,Node.count,300)
    x = XAxis.new
    x.set_labels(months)

    chart = OpenFlashChart.new
    chart.set_title(title)
    chart.add_element(line)
    chart.add_element(vmline)
    chart.x_axis = x
    chart.y_axis = y

    return chart
  end
  
  def global_cpu_percent_chart_method
    data = {}
    data[:days] = []
    data[:values] = []

    # Create datapoints for the past 12 months and keep them in array so that their order is retained
    counter = 10
    while counter > 0
      day = counter
      data[:days] << day.days.ago.strftime("%m/%d")
      values = UtilizationMetricsGlobal.find(
          :all, :select => :value, :joins => {:utilization_metric_name => {}},
          :conditions => ["assigned_at like ? and utilization_metric_names.name = ?", "%#{day.days.ago.strftime("%Y-%m-%d")}%", 'percent_cpu'])
      # each day should only have 1 value, if not then create an averageA
      if values.size == 0 
        value = 0 
      elsif values.size == 1
        value = values.first.value
      else
        value = values.collect{|a| a.value.to_i }.sum / values.size
      end
      data[:values] << value.to_i
      counter -= 1
    end
    PP.pp data
    # Create Graph
    title = Title.new("Global CPU% Utilization")
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
  
  def operating_systems_pie_method
    data = {}
    percent = {}
    pie_values = []
    other = 0
    OperatingSystem.find(:all,:include => {:nodes => {}}).each do |os|
      data[os.name] = os.nodes.size
    end
    @operating_systems_pie_fail = true
    sum = data.values.inject(0) { |s,v| s += v }
    unless sum == 0
      data.each_pair do |os,count|
        if (percent[(count * 100)/sum].nil?) || (percent[(count * 100)/sum].empty?) 
          percent[(count * 100)/sum] = [os]
        else
          percent[(count * 100)/sum] << os 
        end
      end 
    end
    order = percent.keys.sort
    # only take the top hw profiles otherwise pie graph is ugly
    counter = 10
    unless order.empty?
      while counter > 0
        highest_percent = order.pop
        # may be more than 1 hw profile with the same % key
        percent[highest_percent].each do |os|
          if counter > 0
            if (os =~ /windows/i) 
              shortname = os.gsub(/standard edition/i, 'SE')
              shortname.gsub!(/service pack/i, 'SP')
              shortname.gsub!(/Microsoft.*Windows.*Server/, "Windows\n")
              shortname.gsub!(/enterprise edition/i, 'EE')
              shortname.gsub!(/enterprise x64 edition/i, 'EE x64')
              shortname.gsub!(/standard x64 edition/i, 'SE x64')
              shortname.gsub!(/windows\s/i, 'Win')
            elsif (os =~ /red *hat.*centos/i)
              shortname = os.gsub(/red *hat.*centos/i, 'CentOS').gsub(/\sLinux/i, '')
            elsif (os =~ /red *hat.*enterprise/i)
              shortname = os.gsub(/red *hat.*enterprise/i, 'RHEL').gsub(/\sLinux/i, '')
            else
              shortname = os
            end
            pie_values << PieValue.new(data[os], "#{shortname}: #{data[os]}")
            order.empty? ? (counter = 0) : (counter -= 1)
          else
            other += data[os]
          end
        end
      end # while counter > 0
    end
    # Doesn't matter what the OS's are left, we'll just add the # of those os's to "other"
    order.each do |leftover|
      other += leftover
    end
    pie_values << PieValue.new(other, "Other: #{other}")

    # Generate the graph
    title = Title.new("Members of Operating Systems")
    title.set_style('{font-size: 20px; color: #778877}')
    pie = Pie.new
    pie.start_angle = 0
    pie.animate = true
    pie.values = pie_values
    chart = OpenFlashChart.new
    chart.title = title
    chart.add_element(pie)
    chart.bg_colour = '#FFFFFF'
    chart.x_axis = nil
   
    return chart
  end # def 

  def setup_sample_data
	if !Datacenter.find(:first) && !NodeRack.find(:first) && !Node.find(:first)
      
      hp1 = HardwareProfile.new
      hp1.name = 'Sun Microsystems Sun Fire X4100'
      hp1.manufacturer = 'Sun Microsystems'
      hp1.model = 'Sun Fire X4100'
      hp1.rack_size = 1
      hp1.memory = '1GB'
      hp1.disk = '80GB'
      hp1.nics = 3
      hp1.processor_manufacturer = 'AMD'
      hp1.processor_model = 'Opteron'
      hp1.processor_speed = '3GHZ'
      hp1.processor_socket_count = 2
      hp1.processor_count = 1
      hp1.power_supply_slot_count = 2
      hp1.power_supply_count = 1
      hp1.cards = ''
      hp1.description = 'Test Node Type'
      hp1.visualization_color = 'purple'
      hp1.estimated_cost = 8561
      hp1.save

      hp2 = HardwareProfile.new
      hp2.name = 'Dell PowerEdge 1950'
      hp2.manufacturer = 'Dell'
      hp2.model = 'PowerEdge 1950'
      hp2.rack_size = 1
      hp2.memory = '1GB'
      hp2.disk = '80GB'
      hp2.nics = 3
      hp2.processor_manufacturer = 'AMD'
      hp2.processor_model = 'Opteron'
      hp2.processor_speed = '3GHZ'
      hp2.processor_socket_count = 2
      hp2.processor_count = 1
      hp2.power_supply_slot_count = 2
      hp2.power_supply_count = 1
      hp2.cards = ''
      hp2.description = 'Test Node Type 2'
      hp2.save
      
      os1 = OperatingSystem.new
      os1.name = 'Red Hat Enterprise Linux Server 5.2 x86_64'
      os1.vendor = 'Red Hat'
      os1.variant = 'Enterprise Linux Server'
      os1.version_number = '5.2'
      os1.architecture = 'x86_64'
      os1.save

      ng1 = NodeGroup.new(:name => 'web-server', :description => 'All Types of Web Servers')
      ng1.save
      ng2 = NodeGroup.new(:name => 'apache-server', :description => 'Apache Web Server')
      ng2.save
      ngnga1 = NodeGroupNodeGroupAssignment.new(:parent_group => ng1, :child_group => ng2)
      ngnga1.save
      ng3 = NodeGroup.new(:name => 'nginx-server', :description => 'nginx Web Server')
      ng3.save
      ngnga2 = NodeGroupNodeGroupAssignment.new(:parent_group => ng1, :child_group => ng3)
      ngnga2.save
      ng4 = NodeGroup.new(:name => 'firewall', :description => 'Firewall')
      ng4.save
      ng5 = NodeGroup.new(:name => 'firewall-primary', :description => 'Primary Firewall')
      ng5.save
      ngnga3 = NodeGroupNodeGroupAssignment.new(:parent_group => ng4, :child_group => ng5)
      ngnga3.save
      ng6 = NodeGroup.new(:name => 'db', :description => 'DB Server')
      ng6.save
      ng7 = NodeGroup.new(:name => 'db-mysql', :description => 'MySQL DB Server')
      ng7.save
      ngnga4 = NodeGroupNodeGroupAssignment.new(:parent_group => ng6, :child_group => ng7)
      ngnga4.save
      ng8 = NodeGroup.new(:name => 'db-mysql-master', :description => 'MySQL Master DB Server')
      ng8.save
      ngnga5 = NodeGroupNodeGroupAssignment.new(:parent_group => ng7, :child_group => ng8)
      ng9 = NodeGroup.new(:name => 'db-mysql-slave', :description => 'MySQL Slave DB Server')
      ng9.save
      ngnga6 = NodeGroupNodeGroupAssignment.new(:parent_group => ng7, :child_group => ng9)
      ngnga6.save
      ng10 = NodeGroup.new(:name => 'pdu', :description => 'Power Distribution Unit')
      ng10.save
      ng11 = NodeGroup.new(:name => 'network-switch', :description => 'Network Switch')
      ng11.save

      ny = Datacenter.new
      ny.name = "New York"
      ny.save
      
      hardware_profiles = HardwareProfile.find(:all,:include => {:nodes => {}})
      
      node_rack = NodeRack.new(:name => "NY-Rack 001")
      node_rack.save
      dra = DatacenterNodeRackAssignment.new(:datacenter => ny, :node_rack => node_rack)
      dra.save
      
      node_count = 0
      (1..42).to_a.each do |i|
        node_count = node_count + 1
        node = Node.new(:name => "cc" + node_count.to_s)
        status = Status.find_by_name('inservice')
        node.status = status
        node.serial_number = rand(999999)
        node.hardware_profile = HardwareProfile.find_by_name('Sun Microsystems Sun Fire X4100')
        node.operating_system = OperatingSystem.find(:first)
        node.save
        rna = NodeRackNodeAssignment.new(:node_rack => node_rack, :node => node)
        rna.save
        ngna = NodeGroupNodeAssignment.new(:node_group => ng2, :node => node)
        ngna.save
      end
      
      (2..9).to_a.each do |n|
        node_rack = NodeRack.new(:name => "NY-Rack 00"+n.to_s)
        node_rack.save
        dra = DatacenterNodeRackAssignment.new(:datacenter => ny, :node_rack => node_rack)
        dra.save
        
        (1..9).to_a.each do |i|
          node_count = node_count + 1
          node = Node.new(:name => "host" + node_count.to_s)
          status = Status.find_by_name('setup')
          node.status = status
          node.serial_number = rand(999999)
          node.hardware_profile = hardware_profiles[rand(hardware_profiles.length)]
          node.operating_system = OperatingSystem.find(:first)
          node.save
          rna = NodeRackNodeAssignment.new(:node_rack => node_rack, :node => node)
          rna.save
		  ngna = NodeGroupNodeAssignment.new(:node_group => ng3, :node => node)
		  ngna.save
        end
        
      end
      
    end
  end

end

