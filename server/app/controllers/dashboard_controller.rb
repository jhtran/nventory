class DashboardController < ApplicationController

  def index
  end
  
  def setup_sample_data
    if Datacenter.find(:all).length < 1
      
      # Some System Install Defaults
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
      hp1.save
      
      # Some System Install Defaults
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
      
      # Some System Install Defaults
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
      ng3 = NodeGroup.new(:name => 'nginx-server', :description => 'nginx Web Server')
      ng3.save
      ng4 = NodeGroup.new(:name => 'firewall', :description => 'Firewall')
      ng4.save
      ng5 = NodeGroup.new(:name => 'firewall-primary', :description => 'Primary Firewall')
      ng5.save
      ngnga1 = NodeGroupNodeGroupAssignment.new(:parent_group => ng4, :child_group => ng5)
      ngnga1.save
      ng6 = NodeGroup.new(:name => 'db', :description => 'DB Server')
      ng6.save
      ng7 = NodeGroup.new(:name => 'db-mysql', :description => 'MySQL DB Server')
      ng7.save
      ngnga2 = NodeGroupNodeGroupAssignment.new(:parent_group => ng6, :child_group => ng7)
      ngnga2.save
      ng8 = NodeGroup.new(:name => 'db-mysql-master', :description => 'MySQL Master DB Server')
      ng8.save
      ngnga3 = NodeGroupNodeGroupAssignment.new(:parent_group => ng7, :child_group => ng8)
      ngnga3.save
      ng9 = NodeGroup.new(:name => 'pdu', :description => 'Power Distribution Unit')
      ng9.save
      ng10 = NodeGroup.new(:name => 'network-switch', :description => 'Network Switch')
      ng10.save

      # Set the color and U height
      sunny = HardwareProfile.find_by_name('SunFireX4100')
      sunny.visualization_color = 'purple'
      sunny.rack_size = 2
      sunny.estimated_cost = 8561
      sunny.save
      
    
      ny = Datacenter.new
      ny.name = "New York"
      ny.save
      
      hardware_profiles = HardwareProfile.find(:all)
      
      rack = Rack.new(:name => "NY-Rack 001")
      rack.save
      dra = DatacenterRackAssignment.new(:datacenter => ny, :rack => rack)
      dra.save
      
      node_count = 0
      (1..42).to_a.each do |i|
        node_count = node_count + 1
        node = Node.new(:name => "cc" + node_count.to_s)
        status = Status.find_by_name('inservice')
        node.status = status
        node.serial_number = rand(999999)
        node.hardware_profile = HardwareProfile.find_by_name('SunFireX4100')
        node.operating_system = OperatingSystem.find(:first)
        node.save
        rna = RackNodeAssignment.new(:rack => rack, :node => node)
        rna.save
      end
      
      (2..9).to_a.each do |n|
        rack = Rack.new(:name => "NY-Rack 00"+n.to_s)
        rack.save
        dra = DatacenterRackAssignment.new(:datacenter => ny, :rack => rack)
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
          rna = RackNodeAssignment.new(:rack => rack, :node => node)
          rna.save
        end
        
      end
      
    end
  end

end

