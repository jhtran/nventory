require File.dirname(__FILE__) + '/../test_helper'
require 'nodes_controller'

# Re-raise errors caught by the controller.
class NodesController; def rescue_action(e) raise e end; end

class NodesControllerTest < ActionController::TestCase

  def test_get_index
    assert_get_index
  end

  def test_get_new
    assert_get_new
  end
  
  def test_post_create
    # create a new node
    @create_data = { :node => { :name => 'foo1' , :hardware_profile_id => hardware_profiles(:hp_dl360).id } }
    assert_post_create(:node,@create_data)
    newnode1 = assigns(:node)
    assert_equal 'foo1',newnode1.name
    assert_equal 'setup',newnode1.status.name, 'if no status was specified, should default to find and create status named "setup"'
    # create 2nd node
    @create_data[:node][:name] = 'bar1'
    assert_post_create(:node,@create_data)
    newnode2 = assigns(:node)
    assert_equal 'bar1',newnode2.name
    assert newnode2.destroy
    assert newnode1.destroy
    @create_data[:node][:name] = 'foo1'
    
    # test creation if pass operating_system_id 
    @create_data[:node][:operating_system_id] = operating_systems(:cent_os).id
    assert_post_create(:node,@create_data)
    newnode = assigns(:node)
    assert_equal 'cent os 5',newnode.operating_system.name
    assert newnode.destroy
    # test creation if pass operating_system name
    @create_data[:node].delete(:operating_system_id)
    @create_data[:operating_system] = {:name => operating_systems(:cent_os).name}
    assert_post_create(:node,@create_data)
    newnode = assigns(:node)
    assert_equal 'cent os 5',assigns(:node).operating_system.name
    assert newnode.destroy
    @create_data.delete(:operating_system)
    # test creation if pass hardware_profile name
    @create_data[:node].delete(:hardware_profile_id)
    assert_nil @create_data[:node][:hardware_profile_id], "should've been deleted to test create hardare_profile by name"
    @create_data[:hardware_profile] = {:name => hardware_profiles(:hp_dl360).name}
    assert_post_create(:node,@create_data)
    newnode = assigns(:node)
    assert_equal 'HP DL360',newnode.hardware_profile.name
    assert newnode.destroy
    # test creation if pass status name
    assert_nil @create_data[:status], "status shouldn't pre-exist in the create_data hash"
    assert_nil @create_data[:node][:status_id], "status shouldn't pre-exist in the create_data hash"
    @create_data[:status] = {:name => statuses(:inservice).name}
    assert_post_create(:node,@create_data)
    newnode = assigns(:node)
    assert_equal 'inservice',newnode.status.name
    @create_data.delete(:status)
    assert newnode.destroy
    # test creation of pass status id
    assert_nil @create_data[:status], "status shouldn't pre-exist in the create_data hash"
    @create_data[:node][:status_id] = statuses(:inservice).id
    assert_post_create(:node,@create_data)
    newnode = assigns(:node)
    assert_equal 'inservice',newnode.status.name
    @create_data[:node].delete(:status_id)
    assert newnode.destroy
    # test creation of network_interfaces and nested attrs (ip_addresses & network_ports & switch_port)
    @create_data[:network_interfaces] = {}
    @create_data[:network_interfaces][0] = {:name => 'eth0', :interface_type => 'Ethernet', :port => '2/23', :portspeed => 'GigabitEthernet', :switch => 'switch1'}
         # to register to a switch the following need to be specified: 1) interface_type == 'Ethernet', 
             # 2) :switch needs to be a real node pre-existing 3) port needs to be a real outlet pre-existing and name must match the param and must be associated to :switch node
    @create_data[:network_interfaces][0][:ip_addresses] = {}
    @create_data[:network_interfaces][0][:ip_addresses][0] = {:address => '192.168.1.100', :address_type => 'ipv4'}
    @create_data[:network_interfaces][0][:ip_addresses][1] = {:address => '10.1.1.100', :address_type => 'ipv4'}
    @create_data[:network_interfaces][1] = {:name => 'lo'}
    @create_data[:network_interfaces][1][:ip_addresses] = {}
    @create_data[:network_interfaces][1][:ip_addresses][0] = {:address => '127.0.0.1', :address_type => 'ipv4'}
    @create_data[:network_interfaces][1][:ip_addresses][0][:network_ports] = {}
    @create_data[:network_interfaces][1][:ip_addresses][0][:network_ports][0] = {:apps => 'apache', :number => '80', :protocol => 'tcp'}
    @create_data[:network_interfaces][1][:ip_addresses][0][:network_ports][1] = {:apps => 'nfsd', :number => '111', :protocol => 'udp'}
    assert_post_create(:node,@create_data)
    newnode = assigns(:node)
    assert_equal 'eth0', newnode.network_interfaces.first.name
    assert_equal '192.168.1.100', newnode.network_interfaces.first.ip_addresses.first.address
    assert_equal '10.1.1.100', newnode.network_interfaces.first.ip_addresses.last.address
    assert_equal '127.0.0.1', newnode.network_interfaces.last.ip_addresses.last.address
    assert_equal 80, newnode.network_interfaces.last.ip_addresses.last.network_ports.first.number
    assert_equal 'apache', newnode.network_interfaces.last.ip_addresses.last.ip_address_network_port_assignments.first.apps
    assert_equal 111, newnode.network_interfaces.last.ip_addresses.last.network_ports.last.number
    assert_equal 'nfsd', newnode.network_interfaces.last.ip_addresses.last.ip_address_network_port_assignments.last.apps
    assert_equal 'Gi2/23', newnode.network_interfaces.first.switch_port.name
    assert newnode.destroy
    @create_data.delete(:network_interfaces)
    # test creation of storage_controllers and nested attrs (drives & volumes)
    @create_data[:storage_controllers] = {}
    @create_data[:storage_controllers][0] = {:name => 'ide controller'}
    @create_data[:storage_controllers][0][:drives] = {}
    @create_data[:storage_controllers][0][:drives][0] = {:name => 'drive 1:0', :size => '39084202394'}
    @create_data[:storage_controllers][0][:drives][0][:volumes] = {} 
    @create_data[:storage_controllers][0][:drives][0][:volumes] = {}
    @create_data[:storage_controllers][0][:drives][0][:volumes][0] = {:name => 'vol0', :size => '182106613350', :volume_type => 'RAID5'}
    @create_data[:storage_controllers][0][:drives][0][:volumes][1] = {:name => 'vol0:1', :size => '182106613350', :volume_type => 'RAID5'}
    @create_data[:storage_controllers][0][:drives][1] = {:name => 'drive 2:0', :size => '109084202394'}
    @create_data[:storage_controllers][0][:drives][1][:volumes] = {} 
    @create_data[:storage_controllers][0][:drives][1][:volumes][0] = {:name => 'vol1', :size => '1082106613350', :volume_type => 'RAID5'}
    @create_data[:storage_controllers][1] = {:name => 'sata controller'}
    @create_data[:storage_controllers][1][:drives] = {} 
    @create_data[:storage_controllers][1][:drives][0] = {:name => 'drive 3:0', :size => '39084202394'}
    @create_data[:storage_controllers][1][:drives][0][:volumes] = {}
    @create_data[:storage_controllers][1][:drives][0][:volumes][0] = {:name => 'vol2', :size => '182106613350', :volume_type => 'RAID5'}
    @create_data[:storage_controllers][1][:drives][0][:volumes][1] = {:name => 'vol2:1', :size => '182106613350', :volume_type => 'RAID5'}
    @create_data[:storage_controllers][1][:drives][1] = {:name => 'drive 2:0', :size => '109084202394'}
    @create_data[:storage_controllers][1][:drives][1][:volumes] = {}
    @create_data[:storage_controllers][1][:drives][1][:volumes][0] = {:name => 'vol3', :size => '1082106613350', :volume_type => 'RAID5'}
    assert_post_create(:node,@create_data)
    newnode = assigns(:node)
    assert_equal 'ide controller',newnode.storage_controllers.first.name
    assert_equal 'sata controller',newnode.storage_controllers.last.name
    assert_equal 39084202394,newnode.storage_controllers.first.drives.first.size
    assert_equal 109084202394,newnode.storage_controllers.first.drives.last.size
    assert_equal 'vol0',newnode.storage_controllers.first.drives.first.volumes.first.name
    assert_equal 'vol0:1',newnode.storage_controllers.first.drives.first.volumes.last.name
    assert newnode.destroy
    @create_data.delete(:storage_controllers)
    # test creation of rack assignment by id
    @create_data[:node_rack] = {:id => node_racks(:ac1_rack1).id}
    assert_post_create(:node,@create_data)
    assert assigns(:node)
    newnode = assigns(:node)
    assert_equal 'ac1_rack1', newnode.node_rack.name
    assert newnode.destroy
    @create_data.delete(:node_rack)
    # test creation of rack assignment by name
    assert_nil @create_data[:node_rack]
    @create_data[:node_rack] = {:name => node_racks(:ac1_rack1).name}
    assert_post_create(:node,@create_data)
    assert assigns(:node)
    newnode = assigns(:node)
    assert_equal 'ac1_rack1', newnode.node_rack.name
    assert newnode.destroy
    @create_data.delete(:node_rack)
    # test creation of outlets by defining outlet_names
    @create_data.delete(:hardware_profile)
    @create_data[:node][:hardware_profile_id] = hardware_profiles(:cat_6509).id
    @create_data[:node][:outlet_names] = (0..12).collect{|num| "gi0/#{num}"}
    assert_post_create(:node,@create_data)
    assert assigns(:node)
    newnode = assigns(:node)
    assert_equal 12,newnode.produced_outlets.size
    newnode.produced_outlets.each{|outlet| assert_match /gi0/,outlet.name}
    assert newnode.destroy
    @create_data[:node].delete(:outlet_names)
    # test creation of utilization_metrics
    @create_data[:utilization_metric] = {:percent_cpu =>{:value => 4}, :login_count => {:value => 1}}
    assert_post_create(:node,@create_data)
    assert assigns(:node)
    newnode = assigns(:node)
    assert_equal 4.to_s,newnode.utilization_metrics.first.value
    assert_equal 'percent_cpu',newnode.utilization_metrics.first.utilization_metric_name.name
    assert_equal 1.to_s,newnode.utilization_metrics.last.value
    assert_equal 'login_count',newnode.utilization_metrics.last.utilization_metric_name.name
    assert newnode.destroy
    @create_data.delete(:utilization_metric)
    # test creation of volumes
    @create_data[:volumes] = {}
    @create_data[:volumes][:mounted] = {'/mnt/nventory_backup' => {'config' => '/etc/auto.auto', 'type' => 'nfs', 'volume_server' => 'irvnventory1', 'volume' => '/vol/nventory_backup'} }
    assert_post_create(:node,@create_data)
    assert assigns(:node)
    newnode = assigns(:node)
    assert 'irvnventory1',newnode.volumes_mounted.first.volume_server.name
    assert 'nfs',newnode.volumes_mounted.first.volume_type
    assert newnode.destroy
    @create_data.delete(:volumes)
    # test creation of name_aliases
    @create_data[:name_aliases] = {:name => 'foobar1.blah.com,barfoo1.blah.com,barfoo1,foobar1'}
    assert_post_create(:node,@create_data)
    assert assigns(:node)
    newnode = assigns(:node)
    newnode.reload
    assert_equal 4,newnode.name_aliases.size
    assert_equal 'barfoo1',newnode.name_aliases.first.name
    assert newnode.destroy
  end

  def test_post_create_xml
    @create_data = { :node => { :name => 'foo1' , :hardware_profile_id => hardware_profiles(:hp_dl360).id } }
    assert_post_create(:node,@create_data, 'xml')
  end

  def test_get_show
    assert_get_show(:node)
  end

  def test_get_edit
    assert_get_edit(:node)
  end

  def test_put_update
    @update_data = {:id => nodes(:irvnventory1).id, :node => {:name => 'foonewbar'}}
    assert_put_update(:node, @update_data)
    newnode = assigns(:node)
    @update_data[:node].delete(:name)
    # test update of OS if pass operating_system_id 
    assert_nil newnode.operating_system
    @update_data[:node][:operating_system_id] = operating_systems(:cent_os).id
    assert_put_update(:node, @update_data)
    newnode = assigns(:node)
    assert_equal 'cent os 5',newnode.operating_system.name
    @update_data[:node].delete(:operating_system_id)
    # test update of os if pass operating_system name
    assert_put_update(:node, {:id => nodes(:irvnventory1).id, :node => {:operating_system_id => nil}})
    assert_nil assigns(:node).operating_system
    @update_data[:operating_system] = {:name => 'cent os 5'}
    assert_put_update(:node, @update_data)
    assert_equal 'cent os 5',assigns(:node).operating_system.name
    # test update of hardware_profile if pass id
    @update_data[:node][:hardware_profile_id] = hardware_profiles(:cat_6509).id
    assert_put_update(:node, @update_data)
    assert_equal 'Catalyst 6509',assigns(:node).hardware_profile.name
    # test update of hardware_profile if pass name
    @update_data[:node].delete(:hardware_profile_id)
    @update_data[:hardware_profile] = {:name => 'hp dl360'}
    assert_put_update(:node, @update_data)
    assert_equal 'HP DL360',assigns(:node).hardware_profile.name
    # test update of hwp with only model and manufacturer
    @update_data[:hardware_profile].delete(:name)
    @update_data[:hardware_profile] = {:manufacturer => 'apple' , :model => 'macbook pro'}
    assert_put_update(:node, @update_data)
    assert_equal 'Apple Macbook Pro',assigns(:node).hardware_profile.name
    # test update of status by id
    @update_data[:node][:status_id] = statuses(:outofservice).id.to_s
    assert_put_update(:node, @update_data)
    assert_equal 'outofservice',assigns(:node).reload.status.name
    ### TO BE FIXED - something causing old session params to carry over
    ## test update of status by name
#    @update_data[:node].delete(:status_id)
#    assert_put_update(:node, {:id => nodes(:irvnventory1).id, :status => {:name => 'inservice' }})
#    assert_equal 'inservice',assigns(:node).status.name
    # test update of network_interface, switch port & ip address
    @update_data[:network_interfaces] = {}
    @update_data[:network_interfaces][0] = {:name => 'eth0'}
    @update_data[:network_interfaces][0][:ip_addresses] = {}
    @update_data[:network_interfaces][0][:ip_addresses][0] = {:address => '192.168.1.100', :address_type => 'ipv4'}
    @update_data[:network_interfaces][0][:ip_addresses][1] = {:address => '10.1.1.100', :address_type => 'ipv4'}
    @update_data[:network_interfaces][1] = {:name => 'lo'}
    @update_data[:network_interfaces][1][:ip_addresses] = {}
    @update_data[:network_interfaces][1][:ip_addresses][0] = {:address => '127.0.0.1', :address_type => 'ipv4'}
    @update_data[:network_interfaces][1][:ip_addresses][0][:network_ports] = {}
    @update_data[:network_interfaces][1][:ip_addresses][0][:network_ports][0] = {:apps => 'apache', :number => '80', :protocol => 'tcp'}
    @update_data[:network_interfaces][1][:ip_addresses][0][:network_ports][1] = {:apps => 'nfsd', :number => '111', :protocol => 'udp'}
    assert_put_update(:node, @update_data)
    assert_equal 2,assigns(:node).network_interfaces.size
    assert_equal ['eth0','lo'],assigns(:node).network_interfaces.collect(&:name)
    # test update of virtual mode & guests
    @update_data[:node][:virtualarch] = 'xen'
    @update_data[:node][:virtualmode] = 'host'
    @update_data[:vmguest] = {}
    @update_data[:vmguest][:vmguest2] = {:vmimg_size => '1111', :vmspace_used => '1100'}
    assert_put_update(:node, @update_data)
    assert_equal 1,assigns(:node).virtual_guests.size
    assert_equal 'vmguest2',assigns(:node).virtual_guests.first.name
    @update_data.delete(:vmguest)
    # test update of virtual host - registration to a vhost depends on deduction from which host resides on switch port
    @update_data[:node][:virtualmode] = 'guest'
    @update_data[:network_interfaces][0][:interface_type] = 'Ethernet'
    @update_data[:network_interfaces][0][:port] = '2/23'
    @update_data[:network_interfaces][0][:switch] = 'switch1'
    assert_put_update(:node, @update_data)
    assert_equal 'vmhost1',assigns(:node).virtual_host.name
    assert_nil assigns(:node).network_interfaces.first.switch_port, "switch port info shouldn't register when is a vmguest.  the switch info should stay assoc to vmhost"
  end

  def test_put_update_xml
    assert_put_update(:node,{:id => nodes(:irvnventory1).id,:node => {:name => 'foonewbar'}}, 'xml')
  end
  
  def test_delete_destroy
    assert_delete_destroy(:node,nodes(:irvnventory1))
  end

  def test_delete_destroy_xml
    assert_delete_destroy(:node,nodes(:irvnventory1), 'xml')
  end

end
