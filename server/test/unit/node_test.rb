require File.dirname(__FILE__) + '/../test_helper'

class NodeTest < ActiveRecord::TestCase

  def test_setup
    @hardware_profile = hardware_profiles(:hp_dl360) 
    @status = statuses(:inservice)
    assert (@node = Node.create({:name => 'irvnventory3', :status => @status, :hardware_profile => @hardware_profile})), "Unable to save initial @node setup obj"
    assert @node.save, "Unable to save node, immediately after with no changes"
  end

  def test_authorizable
    user = account_groups(:jdoe_self)
    user.has_role 'admin', Node
    assert user.has_role?('admin',Node), "model class unable to assign roles to user"
    user.has_no_role 'admin', Node
    assert !user.has_role?('admin', Node), "model class unable to UN-assign role to user"
  end

  def test_commentable
    node = nodes(:irvnventory1)
    node.comments.create({:title => 'purpose', :comment => 'this server is the first nventory server'})
    assert_match /first nventory server/,node.comments.find_by_title('purpose').comment, "Comment insertion failed"
  end

  def test_auditable
    node = nodes(:irvnventory1)
    assert node.audits.empty?, "audit should be 0 prior to save"
    node.processor_count = 2 and node.save
    assert_equal 1,node.audits.size, "audit should only have 1 after save"
  end

  def test_vip_association
    test_setup
    # Vip :hosted_vips
    nventory_vip_80 = vips(:nventory_vip_80)
    assert @node.hosted_vips.empty?, "Haven't assigned any vips yet ; value should be 0"
    @node.hosted_vips << nventory_vip_80
    assert @node.save, "Unable to save vip assignment"
    assert_equal 1,@node.hosted_vips.size, "After assigning vip, value should be 1"
  end

  def test_node_rack_association
    test_setup
    # NodeRack 
    assert_nil @node.node_rack, "Shouldn't have any :node_rack assigned yet"
    ac1_rack1 = node_racks(:ac1_rack1)
    @node.node_rack = ac1_rack1
    nrna = @node.node_rack_node_assignment
    assert @node.save, "Unable to save node_rack assignment"
    assert Node.find(@node.id), "Node wasn't saved "
    assert nrna, "node rack node asignment not exist"
    assert_equal @node.node_rack.name,'ac1_rack1', "rack_name diff than one assigned"
    nodeid = @node.id
    assert @node.destroy, "Unable to destroy node"
    assert_raises(ActiveRecord::RecordNotFound){Node.find(nodeid)}
    assert_raises(ActiveRecord::RecordNotFound){NodeRackNodeAssignment.find(nrna)}
    assert NodeRack.find(@node.node_rack.id), ":node_rack shouldn't have been destroyed when node was destroyed"
  end

####  TO BE FIXED - fixtures issue ####
#  def test_lb_pool_associations
#    test_setup
#    # LbPool
#    assert @node.lb_pools.empty?, "Shouldn't have any :lb_pools assigned yet"
#    nventory_80_pool = lb_pools(:nventory_80_pool)
#    @node.lb_pools << nventory_80_pool 
#    assert_equal 1,@node.lb_pool_node_assignments.size
#    lpna = @node.lb_pool_node_assignments.first
#    lpid = nventory_80_pool.id
#    assert @node.save, "Unable to save lb_pool assignment"
#    assert Node.find(@node.id), "Node wasn't saved "
#    assert lpna, "node lb_pool assignment not exist"
#    assert_equal @node.lb_pools.first.name,'nventory_80_pool', "lb_pool diff than one assigned"
#    nodeid = @node.id
#    assert @node.destroy, "Unable to destroy node"
#    assert_raises(ActiveRecord::RecordNotFound){Node.find(nodeid)}
#    assert_raises(ActiveRecord::RecordNotFound){LbPoolNodeAssignment.find(lpna)}
#    assert LbPool.find(lpid), ":lb_pool shouldn't have been destroyed when node was destroyed"
#  end

  def test_volume_associations
    test_setup
    # Volume
    backup_volume = volumes(:backup_volume)
    shared_space_volume = volumes(:shared_space_volume)
    assert @node.volumes_served.empty?, "Shouldn't have any :volumes_served assigned yet"
    @node.volumes_served << backup_volume
    assert @node.save, "Volume served assignment won't save"
    assert_equal 1,@node.volumes_served.size, "# of volumes served mismatch"
    assert @node.volume_node_assignments.empty?, "Shouldn't have any volume_node_assignments yet - this is for volumes mounted"
    assert @node.volumes_mounted.empty?, "Shouldn't have any volume_mounted yet"
    assert_raises(ActiveRecord::RecordInvalid){@node.volumes_mounted << shared_space_volume} # "saved without specifying the mount attr for VolumeNodeAssignment"
    volume_node_assignment = VolumeNodeAssignment.create({:volume => shared_space_volume, :node => @node, :mount => '/mnt10'})
    assert volume_node_assignment, "VolumeNodeAssignment wasn't created"
    assert_equal @node,volume_node_assignment.node, "VolumeNodeAssignment node not assigned correct"
    assert_equal shared_space_volume,volume_node_assignment.volume, "VolumeNodeAssignment mounted_volume not correct"
    assert_match /mnt10/,volume_node_assignment.mount, "VolumeNodeAssignment mount point incorrect"
    assert_equal 1,@node.volumes_mounted.size, "# of volumes mounted mismatch"
    assert @node.reload, "unable to reload node info"
    assert_equal 1,@node.volume_node_assignments.size, "# of volume_node_assignments mismatch"
    assert_equal 1,@node.volumes_mounted.size, "# of volumes_mounted mismatch"
  end

  def test_hardware_profile_association
    test_setup
    # HardwareProfile
    assert_equal 'HP DL360',@node.hardware_profile.name, "Hardware Profile mismatch"
    @node.hardware_profile = HardwareProfile.create({:name => 'macbook air'})
    assert @node.save, 'Unable to save new hardware profile to node'
    assert_equal 'macbook air',@node.reload.hardware_profile.name, 'hardware profile mismatch'
  end

  def test_operating_system_association
    test_setup
    # OperatingSystem
    assert_nil @node.operating_system, "Operating System name should be nil - have not assigned yet"
    @node.operating_system = OperatingSystem.create({:name => 'CentOS 5.9'})
    assert @node.save, 'Unable to save new Operating System to node'
    assert_equal 'CentOS 5.9',@node.reload.operating_system.name, 'operating system mismatch'
  end

  def test_status_association
    test_setup
    # OperatingSystem
    assert_equal 'inservice',@node.status.name, "Status mismatch"
    @node.status = Status.create({:name => 'retired'})
    assert @node.save, 'Unable to save new Status to node'
    assert_equal 'retired',@node.reload.status.name, 'status mismatch'
  end

  def test_node_group_association
    test_setup
    # NodeGroup
    assert @node.node_group_node_assignments.empty?, "should be empty, none assigned yet"
    assert @node.node_groups.empty?, "should be empty, none assigned yet"
    assert (@node.node_groups << NodeGroup.create({:name => 'nventory_ng'})), "Unable to create node_group/ngna"
    assert_equal 1,@node.node_group_node_assignments.size, "node_group assignment didn't save"
    assert_equal 1,@node.node_groups.size, "node_group_assignment didn't save"
    assert (@node.node_groups << NodeGroup.create({:name => 'nventory_ng2'})), "Unable to create node_group/ngna"
    assert_equal 2,@node.node_group_node_assignments.size, "2nd node_group assignment didn't save"
    assert_equal 2,@node.node_groups.size, "2nd node_group_assignment didn't save"
  end

  def test_node_group_destroy
    test_node_group_association
    nventory_ngid = @node.node_groups.first.id
    nventory_ng2id = @node.node_groups.last.id
    nodeid = @node.id
    assert (@node.destroy), "Unable to destroy node group"
    assert_raises(ActiveRecord::RecordNotFound){Node.find(nodeid)}
    assert_equal 'nventory_ng', NodeGroup.find(nventory_ngid).name, 'node_group mismatch'
    assert_equal 'nventory_ng2', NodeGroup.find(nventory_ng2id).name, 'node_group mismatch'
    ## Need to add test for accept_nested_attrs
  end

  def test_service_association
    test_setup
    # Service
    ## services are aliases of node_groups except with additional service_profile
    assert @node.node_group_node_assignments.empty?, "should be empty, none assigned yet" 
    assert @node.services.empty?, "should be empty, none assigned yet"
    assert (@node.services << Service.create({:name => 'nventory_svc'})), "Unable to create service or ngna"
    assert_equal 1,@node.node_group_node_assignments.size, "service assignment (ngna) didn't save"
    assert_equal 1,@node.services.size, "service count mismatch"
    assert (@node.services << Service.create({:name => 'nventory_svc2'})), "Unable to create service or ngna"
    assert_equal 2,@node.node_group_node_assignments.size, "service count mismatch"
    assert_equal 2,@node.services.size, "2nd service assignment didn't save"
  end

  def test_service_destroy
    test_service_association
    nventory_svcid = @node.services.first.id
    nventory_svc2id = @node.services.last.id
    nodeid = @node.id
    assert (@node.destroy), "Unable to destroy node group"
    assert_raises(ActiveRecord::RecordNotFound){Node.find(nodeid)}
    assert_equal 'nventory_svc', Service.find(nventory_svcid).name
    assert_equal 'nventory_svc2', Service.find(nventory_svc2id).name
  end

  def test_services?
    test_service_association
    ## possibly broken need to FIX
    #assert @node.services?, 'has one service, yet came back false'
    noservices = Node.create({:name => 'noservicenode', :hardware_profile => hardware_profiles(:hp_dl360), :status => statuses(:inservice)})
    assert_equal false,@node.services?, 'should have no services'
  end

  def test_database_instance_association
    test_setup
    # NodeGroup
    assert @node.node_database_instance_assignments.empty?, "should be empty, none assigned yet"
    assert @node.database_instances.empty?, "should be empty, none assigned yet"
    assert (@node.database_instances << DatabaseInstance.create({:name => 'db_inst1'})), "Unable to create database instance or assignment"
    assert_equal 1,@node.node_database_instance_assignments.size, "database instance assignment didn't save"
    assert_equal 1,@node.database_instances.size, "node_database_instance_assignment didn't save"
    assert (@node.database_instances << DatabaseInstance.create({:name => 'db_inst2'})), "Unable to create database instance or assignment"
    assert_equal 2,@node.node_database_instance_assignments.size, "2nd database instance assignment didn't save"
    assert_equal 2,@node.database_instances.size, "2nd database instance assignment didn't save"
  end

  def test_database_instance_destroy
    test_database_instance_association
    db_instid = @node.database_instances.first.id
    db_inst2id = @node.database_instances.last.id
    nodeid = @node.id
    assert_raises(RuntimeError){@node.destroy}
    @node.database_instances.each{|instance| assert instance.destroy, "unable to destroy database instance"}
    assert_raises(ActiveRecord::RecordNotFound){DatabaseInstance.find(db_instid)}
    assert_raises(ActiveRecord::RecordNotFound){DatabaseInstance.find(db_inst2id)}
    assert @node.destroy, "Unable to destroy node, even tho all db instances have been removed and destroyed"
    assert_raises(ActiveRecord::RecordNotFound){Node.find(nodeid)}
  end

  def test_outlet_association
    test_setup
    # Outlet
    assert @node.consumed_outlets.empty?, "should be empty, none assigned yet"
    assert @node.produced_outlets.empty?, "should be empty, none assigned yet"
    # make @node into a network producer.  Relationship of network outlet<=>network_interface; whereas relationship of all other outlet<=>node.
    @node.hardware_profile.outlet_type = 'Network'
    @node.hardware_profile.outlet_count = 0
    assert @node.hardware_profile.save
    assert_equal 'Network',@node.hardware_profile.outlet_type
    assert_equal 0,@node.hardware_profile.outlet_count
    assert (@node.produced_outlets << Outlet.create({:name => 'gi1/1',:consumer_type => 'NetworkInterface'}))
    assert @node.save, 'unable to save produced outlet'
    assert_equal 1,@node.produced_outlets.size, "produced outlet didn't save"
    assert @node.consumed_outlets.empty?, "consumed outlet count mismatch"
    # create a blade producer 
    blade_profile = HardwareProfile.create({:name => 'blade_chassis', :outlet_type => 'Blade', :outlet_count => 0})
    blade_server = Node.create({:name => 'blade_server1', :hardware_profile => blade_profile, :status => statuses(:inservice)})
    assert blade_profile.save, "Problems creating/saving blade hardware_profile"
    assert blade_server.save, "Problems creating or saving blade server node"
    blade_server.produced_outlets << Outlet.create({:name => 'slot0', :consumer => @node})
    assert blade_server.save, "Unable to create or save blade_server outlet and assign it to @node"
    assert_equal 1,blade_server.produced_outlets.size, "blade producer # of consumer mismatch"
    assert_equal @node,blade_server.produced_outlets.first.consumer, "blade consumer <=> @node mismatch"
    assert_equal 1,@node.reload.consumed_outlets.size, "@node's consumed_outlets method # mismatch"
    assert_equal 'slot0',@node.consumed_outlets.last.name, "@node's consumed_outlet name isn't the same as what we created"
    # create a serial console producer
    serialconsole_profile = HardwareProfile.create({:name => 'serial_console', :outlet_type => 'Console', :outlet_count => 0})
    serialconsole_server = Node.create({:name => 'serialconsole_server1', :hardware_profile => serialconsole_profile, :status => statuses(:inservice)})
    assert serialconsole_profile.save, "Problems creating/saving serialconsole hardware_profile"
    assert serialconsole_server.save, "Problems creating or saving serialconsole server node"
    serialconsole_server.produced_outlets << Outlet.create({:name => 's0', :consumer => @node})
    assert serialconsole_server.save, "Unable to create or save serialconsole_server outlet and assign it to @node"
    assert_equal 1,serialconsole_server.produced_outlets.size, "serialconsole producer # of consumer mismatch"
    assert_equal @node,serialconsole_server.produced_outlets.first.consumer, "serialconsole consumer <=> @node mismatch"
    ### *** SERIAL CONSOLE OUTLETS MIGHT BE BROKEN, NEED TO REVISIT *** ###
    #assert_equal 2,@node.reload.consumed_outlets.size, "@node's consumed_outlets method # mismatch"
    #assert_equal 's0',@node.consumed_outlets.last.name, "@node's consumed_outlet name isn't the same as what we created"
    # create a power outlet producer
    power_profile = HardwareProfile.create({:name => 'power_outlet_profile', :outlet_type => 'Power', :outlet_count => 0})
    power_outlet = Node.create({:name => 'power_outlet', :status => Status.last, :hardware_profile => power_profile})
    assert power_outlet.save, "Unable to save power_outlet node"
    power_outlet.produced_outlets << Outlet.create({:name => 'power_port1'})
    assert power_outlet.save, "Unable to create an outlet port for the power_outlet"
    assert_equal 1,power_outlet.produced_outlets.size, "# of produced outlets mismatch"
    outlet = power_outlet.produced_outlets.first
    assert (outlet.consumer = @node), "unable to assign @node to the power_outlet"
    assert outlet.save, "unable to assign @node to the power_outlet"
    # Verify @node sees all these consumed_outletsA
    assert_equal 2,@node.reload.consumed_outlets.size
    assert_equal 'Blade',@node.consumed_outlets.first.producer.hardware_profile.outlet_type
    assert_equal 'Power',@node.consumed_outlets.last.producer.hardware_profile.outlet_type
  end

  def test_consumed_outlets
    test_outlet_association
    assert @node.reload, "unable to refresh @node info"
    # consumed_network_outlets
    assert_equal 'gi1/1',@node.produced_outlets.first.name
    assert (@desktop1 = Node.create({:name => 'desktop1', :hardware_profile => hardware_profiles(:hp_dl360), :status => statuses(:inservice)})), "unable to create desktop node"
    assert (@desktop1.network_interfaces << NetworkInterface.create({:name => 'eth0'})), "unable to assign nic to @desktop1"
    assert @desktop1.save, "unable to save nic to @desktop1"
    assert_equal 1,@desktop1.network_interfaces.size , "should have a nic assigned"
    outlet = @node.produced_outlets.first
    outlet.consumer = @desktop1.network_interfaces.first
    assert outlet.save, "unable to save outlet assignment @desktop1 nic to @node produced network switch outlet"
    assert_equal 1,@desktop1.consumed_network_outlets.size, "@desktop1 # of consumed network outlets mismatch should be 1"
    # consumed_power_outlets
    assert_equal 1,@node.consumed_power_outlets.size, "@node should have 1 consumed power"
    # consumed_console_outlets
    ## broken - need to FIX
    # consumed_blade
    assert_equal 'slot0',@node.consumed_blade.name, "blade name mismatch"
  end

  def test_outlet_destroy
    test_consumed_outlets
    nicid = @desktop1.network_interfaces.first.id
    switchportid = @node.produced_outlets.first.id
    assert @desktop1.destroy, 'unable to destroy @desktop1'
    # ensure destroys @desktop1 nic
    assert_raises(ActiveRecord::RecordNotFound){NetworkInterface.find(nicid)}
    # ensure destroys @node outlet
    assert_raises(ActiveRecord::RecordNotFound){Outlet.find(switchportid)}
    # consumed ports shouldn't be destroyed
    bladeoutletid = @node.consumed_outlets.first.id
    poweroutletid = @node.consumed_power_outlets.last.id
    assert Outlet.find(bladeoutletid), "blade outlet got destroyed"
    assert Outlet.find(poweroutletid), "power outlet got destroyed"
  end

  def test_name_alias_association
    test_setup
    # NameAlias
    assert (@node.name_aliases << NameAlias.create({:name => 'irvnventory3.flight.example.com', :source => @node})), "Unable to create new name alias obj"
    assert @node.save, "unable to save name alias"
    assert NameAlias.find_by_name('irvnventory3.flight.example.com'), 'name alias could not be found'
  end

  def test_name_alias_destroy
    test_name_alias_association
    naliasid = @node.name_aliases.first.id
    assert @node.destroy, "Unable to destroy node"
    assert_raises(ActiveRecord::RecordNotFound){NameAlias.find(naliasid)}
  end

  def test_names
    test_name_alias_association
    assert_equal 2,@node.names.size
  end

  def test_network_interface_association
    test_setup
    # NetworkInterface
    assert @node.network_interfaces.empty?, "Shouldn't have any nics defined yet"
    # create 1st nic
    assert (@node.network_interfaces << NetworkInterface.create({:name => 'eth0'})), "unable to create nic for @node"
    assert_equal 1,@node.network_interfaces.size, "# nic mismatch"
    nic = @node.network_interfaces.first
    assert nic.object_id, "nic create failure, no id assigned"
    assert @node.save, "unable to save nic to @node"
    # create 2nd nic
    assert (@node.network_interfaces << NetworkInterface.create({:name => 'lo'})), "unable to create nic for @node"
    assert_equal 2,@node.network_interfaces.size, "# nic mismatch"
    nic2 = @node.network_interfaces.last
    assert nic2.object_id, "nic create failure, no id assigned"
    assert @node.destroy, "unable to destroy node"
    assert_raises(ActiveRecord::RecordNotFound){NetworkInterface.find(nic.object_id)}
    assert_raises(ActiveRecord::RecordNotFound){NetworkInterface.find(nic2.object_id)}
  end
 
  def test_ip_address_association
    test_setup
    # IpAddress
    assert @node.ip_addresses.empty?, "Shouldn't have any ips defined yet"
    # create 1st nic
    assert (@node.network_interfaces << NetworkInterface.create({:name => 'eth0'})), "unable to create nic for @node"
    assert_equal 1,@node.network_interfaces.size, "# nic mismatch"
    nic = @node.network_interfaces.first
    # create 1st ip
    assert (nic.ip_addresses << IpAddress.create({:address => '192.168.1.100', :address_type => 'ipv4'})), "unable to create ip for @node"
    assert @node.save, "unable to save ip to @node"
    assert_equal 1,@node.ip_addresses.size, "# ip mismatch"
    ip = nic.ip_addresses.first
    assert ip.object_id, "ip create failure, no id assigned"
    # create 2nd nic
    assert (@node.network_interfaces << NetworkInterface.create({:name => 'lo'})), "unable to create nic for @node"
    assert_equal 2,@node.network_interfaces.size, "# nic mismatch"
    nic2 = @node.network_interfaces.last
    assert nic2.object_id, "nic create failure, no id assigned"
    # create 2nd ip
    assert (nic2.ip_addresses << IpAddress.create({:address => '127.0.0.1', :address_type => 'ipv4'})), "unable to create ip for @node"
    assert @node.save, "unable to save ip to @node"
    assert_equal 2,@node.ip_addresses.size, "# ip mismatch"
  end

  def test_ip_address_destroy
    test_ip_address_association
    nic = @node.network_interfaces.first
    ip = nic.ip_addresses.first
    nic2 = @node.network_interfaces.last
    ip2 = nic2.ip_addresses.last
    assert ip2.object_id, "ip create failure, no id assigned"
    assert @node.destroy, "unable to destroy node"
    assert_raises(ActiveRecord::RecordNotFound){IpAddress.find(ip.object_id)}
    assert_raises(ActiveRecord::RecordNotFound){IpAddress.find(ip2.object_id)}
  end

  def test_storage_controller_association
    test_setup
    # StorageController
    assert @node.storage_controllers.empty?, "Shouldn't have any storage controllers defined yet"
    # create 1st storage controller
    assert (@node.storage_controllers << StorageController.create({:name => 'scsi0'})), "unable to create storage controller for @node"
    assert_equal 1,@node.storage_controllers.size, "# storage controller mismatch"
    sc = @node.storage_controllers.first
    assert sc.object_id, "storage controller create failure, no id assigned"
    assert @node.save, "unable to save storage controller to @node"
    # create 2nd storage controller
    assert (@node.storage_controllers << StorageController.create({:name => 'ide1'})), "unable to create storage controller for @node"
    assert_equal 2,@node.storage_controllers.size, "# storage controller mismatch"
    sc2 = @node.storage_controllers.last
    assert sc.object_id, "storage controller create failure, no id assigned"
    assert @node.destroy, "unable to destroy node"
    assert_raises(ActiveRecord::RecordNotFound){NetworkInterface.find(sc.object_id)}
    assert_raises(ActiveRecord::RecordNotFound){NetworkInterface.find(sc2.object_id)}
  end

  def test_drive_association
    test_setup
    # Drive
    assert @node.storage_controllers.empty?, "Shouldn't have any storage controllers defined yet"
    # create 1st storage controller
    assert (@node.storage_controllers << StorageController.create({:name => 'scsi0'})), "unable to create storage controller for @node"
    assert_equal 1,@node.storage_controllers.size, "# storage controller mismatch"
    sc = @node.storage_controllers.first
    assert sc.object_id, "storage controller create failure, no id assigned"
    assert @node.save, "unable to save storage controller to @node"
    # create 1st drive
    assert (sc.drives << Drive.create({:name => 'sd0'})), "unable to create drive for @node"
    assert @node.save, "unable to save drive to @node"
    assert_equal 1,@node.drives.size, "# drives mismatch"
    drive = sc.drives.first
    assert drive.object_id, "drive create failure, no id assigned"
    # create 2nd storage controller
    assert (@node.storage_controllers << StorageController.create({:name => 'ide1'})), "unable to create storage controller for @node"
    assert_equal 2,@node.storage_controllers.size, "# storage controller mismatch"
    sc2 = @node.storage_controllers.last
    assert sc2.object_id, "storage controller create failure, no id assigned"
    # create 2nd drive
    assert (sc2.drives << Drive.create({:name => 'hd0'})), "unable to create drive for @node"
    assert @node.save, "unable to save drive to @node"
    assert_equal 2,@node.drives.size, "# drives mismatch"
    drive2 = sc.drives.last
    assert drive2.object_id, "drive create failure, no id assigned"
    assert_raises(ActiveRecord::RecordNotFound){Drive.find(drive.object_id)}
    assert_raises(ActiveRecord::RecordNotFound){Drive.find(drive2.object_id)}
  end

  def test_utilization_metric_association
    test_setup
    # UtilizationMetric
    nodeid = @node.id
    assert (@node.utilization_metrics << UtilizationMetric.create({:utilization_metric_name => utilization_metric_names(:percent_cpu), :value => '1'})), "Unable to create utilization metric for @node"
    assert_equal 1,@node.utilization_metrics.size, "utilization metrics # mismatch, should only have one"
    assert (@node.utilization_metrics << UtilizationMetric.create({:utilization_metric_name => utilization_metric_names(:percent_cpu), :value => '1'})), "Unable to create utilization metric for @node"
    assert_equal 2,@node.utilization_metrics.size, "utilization metrics # mismatch, should now have two"
    assert @node.save, "unable to save @node"
    assert_equal 2,UtilizationMetric.find_all_by_node_id(nodeid).size
    assert @node.destroy, "unable to destroy @node"
    assert UtilizationMetric.find_all_by_node_id(nodeid).empty?
  end

  def test_virtual_assignment_association
    test_setup
    # VirtualAssignment
    assert @node.virtual_assignments_as_host.empty?, "virtual assignments # mismatch- shouldn't be any yet"
    assert_nil @node.virtual_host, "virtual guest assignments shouldn't exist yet - haven't assigned"
    assert_nil @node.virtual_assignment_as_guest, "virtual guest assignment to a virtual host shouldn't exist yet - haven't assigned"
    assert @node.virtual_guests.empty?, "virtual guests # mismatch- shouldn't be any yet"
    assert (@node.virtual_guests << Node.create({:name => 'vmguest11', :hardware_profile => hardware_profiles(:hp_dl360), :status => statuses(:inservice) })), "unable to create vmguest node"
    vmguest11 = @node.virtual_guests.first
    vmguest11id = vmguest11.id
    vmga1id = @node.virtual_assignments_as_host.first.id
    assert vmguest11.id, "vmguest11 didn't save, no id assigned"
    assert (@node.virtual_guests << Node.create({:name => 'vmguest22', :hardware_profile => hardware_profiles(:hp_dl360), :status => statuses(:inservice) })), "unable to create vmguest node"
    vmguest22 = @node.virtual_guests.last
    vmguest22id = vmguest22.id
    vmga2id = @node.virtual_assignments_as_host.last.id
    assert vmguest22.id, "vmguest11 didn't save, no id assigned"
    assert_equal 2,@node.reload.virtual_guests.size, "# of vmguests mismatch - should be two"
    assert_equal 2,@node.virtual_assignments_as_host.size, "# of vmguests mismatch - should be two"
    assert @node.save, "unable to save @node after assigning vmguests"
    assert_nil @node.virtual_assignment_as_guest, "virtual guest assignments to a virtual host shouldn't exist yet - haven't assigned"
    assert_nil @node.virtual_host, "virtual guest assignments shouldn't exist yet - haven't assigned"
    assert (@node.virtual_host = Node.create({:name => 'vmhost1', :hardware_profile => hardware_profiles(:hp_dl360), :status => statuses(:inservice) })), "unable to create vmhost node"
    assert @node.save, "unable to save @node after assigning a vmhost"
    assert_equal 'vmhost1',@node.reload.virtual_host.name, "vmhost1 doesn't exist even after saving @node"
    vmhostid = @node.virtual_host.id
    assert @node.destroy, "Unable to destroy node"
    assert_raises(ActiveRecord::RecordNotFound){VirtualAssignment.find(vmga1id)}
    assert_raises(ActiveRecord::RecordNotFound){VirtualAssignment.find(vmga2id)}
    assert Node.find(vmguest11id), "vmguest no longer exists.  destroying node shouldn't delete vmguest"
    assert Node.find(vmguest22id), "vmguest no longer exists.  destroying node shouldn't delete vmguest"
    assert Node.find(vmhostid), "vmhost no longer exists.  destroying node shouldn't delete vmhost"
  end

  def test_validate_presence_of
    node = Node.new
    assert !node.save, "Saved the node without hw_profile or status or name!"
    node.hardware_profile = hardware_profiles(:hp_dl360)
    assert !node.save, "Saved the node without status or name!"
    node.status = statuses(:inservice)
    node.hardware_profile = nil
    assert !node.save,  "Saved the node without a hardware_profile or name!"
    node.status = nil
    node.name = "irvnventory3"
    assert !node.save,  "Saved the node without a hardware_profile or status!"
    node.status = statuses(:inservice)
    assert !node.save, "Saved the node without hardware_profile!"
    node.hardware_profile = hardware_profiles(:hp_dl360)
    node.status = nil
    assert !node.save, "Saved the node without status!"
    node.status = statuses(:inservice)
    node.name = nil
    assert !node.save, "Saved the node without name!"
    node.name = "irvnventory3"
    assert node.save, "Unable to save node although met minimum validate_prescence_of requirements!"
  end

  def test_validates_uniqueness_of
    test_setup
    # :name
    assert (newnode = Node.create({:name => 'irvnventory3', :status => @status, :hardware_profile => @hardware_profile}))
    assert !newnode.save, "was able to save a new node using same name as @node - unique name validation fail"
    newnode.name = 'irvnventory3-1'
    assert newnode.save, "unable to save newnode although changed to a unique name"
    # :uniqueid
    @node.uniqueid = '12345'
    assert @node.save, "unable to save uniqued to @node"
    newnode.uniqueid = '12345'
    assert !newnode.save, 'was able to save a new node using same uniqueid as @node - unique uniqueid validation fail'
    newnode.uniqueid = '67890'
    assert newnode.save, 'unable to save new node although changed to a unique uniqueid'
    newnode.uniqueid = ''
    assert newnode.save, 'unable to save new node after giving blank string (legitimate)'
    newnode.uniqueid = nil
    assert newnode.save, 'unable to save new node after giving nil value (legitimate)'
  end

  def test_validates_numericality_of
    test_setup
    nerror = "able to save @node despite non-numerical value of field"
    zerror = "able to save @node despite value of less than 0 field"
    yerror = "unable to save node with nil field should be allowed"
    [:processor_socket_count, :processor_count,  :processor_core_count, :os_processor_count, :power_supply_count].each do |field|
      @node.send(field.to_s + '=', '1a')
      assert !@node.save, nerror
      @node.send(field.to_s + '=', -1)
      assert !@node.save, zerror
      @node.send(field.to_s + '=',nil)
      assert @node.save, yerror
    end
  end

  def test_validates_inclusion_of
    test_setup
    # outlet console type
    @node.console_type = 'VT100' # bad console type on purpose
    assert !@node.save, "@node saved with a bad console type"
    @node.console_type = nil
    assert @node.save, "@node wasn't allowed to save with nil console_type value, although it should"
    @node.console_type = 'Serial'
    assert @node.save, "@node didn't save with valid console type"
  end

  def test_validate 
    test_setup
    # validates_contact
    @node.contact = nil
    assert @node.save, "didn't allow save with nil contact"
    @node.contact = "someone@blah.com"
    if SSO_AUTH_SERVER
      assert !@node.save, "was able to save with invalid sso account as contact"
      @node.contact = 'jtran'
      assert @node.save, 'unable to save @node with valid sso account as contact'
    else
      puts "\n*****SSO DISABLED*****\n"
      assert @node.save, "unable to save contact"
    end
    # validates_virtualarch
    assert @node.save, "@node unable to save"
    @node.virtualarch = nil
    assert @node.save, "didn't allow save with nil virtualarch"
    @node.virtualarch = 'xenu'
    assert !@node.save, "allowed save with invalid virtualarch"
    @node.virtualarch = 'xen'
    assert @node.save, "can't save altho valid virtualarch"
    @node.virtualarch = 'vmware'
    assert @node.save, "can't save altho valid virtualarch"
  end

  def test_virtual_host?
    test_setup
    assert !@node.virtual_host?, "not a vhost"
    @node.virtual_guests << Node.create({:name => 'vmguest1', :hardware_profile => hardware_profiles(:hp_dl360), :status => statuses(:inservice), :virtualarch => 'xen'})
    assert @node.save, "unable to save virtual guests to @node"
    assert_equal 1,@node.virtual_guests.size, "# of virtual guests mismatch"
    assert @node.virtual_host?, "is a host, should've been true"
  end

  def test_virtual_guest?
    test_setup
    assert !@node.virtual_guest?, "not a virtual guest yet"
    vhost = Node.create({:name => 'vhost1', :hardware_profile => hardware_profiles(:hp_dl360), :status => statuses(:inservice), :virtualarch => 'xen'})
    assert vhost.save, "unable to create virtual host to assign @node to"
    assert vhost.virtual_guests << @node, "unable to assign @node as a virtual guest to vhost"
    assert vhost.save, "unable to save @node as a virtual guest to vhost"
    assert @node.reload.virtual_guest?, "@node doesn't see itself as virtual guest machine, altho has been assigned to vhost "
  end

  def test_real_virtual_node_group_node_assignments
    test_node_group_association
    assert_equal 2,@node.node_groups.size, "should have 2 node_groups"
    assert_equal 2,@node.node_group_node_assignments.size, "should have 2 ngna"
    assert_equal 2,@node.real_node_group_node_assignments.size, "should have 2 real ngna"
    assert_equal 2,@node.real_node_groups.size, "should have 2 real ng"
    assert @node.virtual_node_group_node_assignments.empty?, "should have 0 virtual ngna"
    assert @node.virtual_node_groups.empty?, "should have 0 virtual ng"
    assert (parentng = NodeGroup.create({:name => 'parentng'})), 'unable to create parent ng'
    assert parentng.save, "unable to save parent group"
    myng = @node.node_groups.first
    myng.parent_groups << parentng
    assert myng.save, "unable to save node group after assigning to a parent group"
    assert_equal 3,@node.reload.node_group_node_assignments.size
    assert_equal 2,@node.real_node_group_node_assignments.size, "should have 2 real ngna"
    assert_equal 2,@node.real_node_groups.size, "should have 2 real ng"
    assert_equal 1,@node.virtual_node_group_node_assignments.size, "should have 2 virtual (inherited) ngna"
    assert_equal 1,@node.virtual_node_groups.size, "should have 2 virtual (inherited) ng"
    ## This method is broken need to FIX
    #assert_equal 3,Node.find(@node.id).recursive_real_node_groups.size, "Should have 3 recurisve ng"
  end

  def test_reset_node_groups
    test_real_virtual_node_group_node_assignments
    assert_equal 3,@node.node_groups.size, "should be 3 node_groups from prior test"
    assert @node.reset_node_groups, 'resetting node_groups failed'
    assert @node.node_groups.empty?, 'after reset, shouldnt have any node_groups'
  end

  def test_update_outlets
    # to be done
  end

  def test_add_remove_bottom_outlet
    # to be done
  end

  def test_after_save
    # to be done - updates outlets
  end

  def test_ips
    test_ip_address_association
    assert_equal 1,@node.ips.size
  end

  def test_before_destroy
    test_database_instance_association
    # shouldn't be able to destroy @node if has db instances attached
    assert_raises(RuntimeError){@node.destroy}
  end

end
