class CreateToolTips < ActiveRecord::Migration
  def self.up
    create_table :tool_tips do |t|
      t.column :model, :string
      t.column :attr, :string
      t.column :description, :text
      t.column :created_at,     :datetime
      t.column :updated_at,     :datetime
    end
    add_index :tool_tips, :model
    add_index :tool_tips, :attr
    add_index :tool_tips, :created_at
    add_index :tool_tips, :updated_at
    # Add some default tooltips
    ToolTip.reset_column_information
    ToolTip.create :model => 'Node',
                   :attr=> 'status',
                   :description => 'Current state of node'
    ToolTip.create :model => 'Node',
                   :attr=> 'name_aliases',
                   :description => 'Other names this node known by'
    ToolTip.create :model => 'Node',
                   :attr=> 'contact',
                   :description => 'A user whom is point of contact <br />for this node'
    ToolTip.create :model => 'NodeRack',
                   :attr=> 'datacenter',
                   :description => 'Where servers are hosted'
    ToolTip.create :model => 'Node',
                   :attr=> 'node_rack',
                   :description => 'Where servers are mounted, within a datacenter'
    ToolTip.create :model => 'volume_node_assignment',
                   :attr=> 'volume',
                   :description => 'Network storage, shared by a node'
    ToolTip.create :model => 'Account',
                   :attr=> 'login',
                   :description => 'Local user account login'
    ToolTip.create :model => 'Node',
                   :attr=> 'node_groups',
                   :description => 'Organizational object for nodes'
    ToolTip.create :model => 'Node',
                   :attr=> 'services',
                   :description => 'Applications a node belongs to'
    ToolTip.create :model => 'Node',
                   :attr=> 'lb_pools',
                   :description => 'Group of nodes that serve a VIP'
    ToolTip.create :model => 'VipLbPoolAssignment',
                   :attr=> 'vip',
                   :description => 'Virtual IP Address - usually hosted by a Load Balancer'
    ToolTip.create :model => 'Node',
                   :attr=> 'hardware_profiles',
                   :description => 'Hardware specifications and type of node'
    ToolTip.create :model => 'Node',
                   :attr=> 'operating_system',
                   :description => 'Interface between hardware and software of a node'
    ToolTip.create :model => 'Node',
                   :attr=> 'produced_outlets',
                   :description => 'Network ports, power outlets, or console ports<br />shared by a node'
    ToolTip.create :model => 'NodeGroup',
                   :attr=> 'subnets',
                   :description => "Each identifiably separate part of an organization's network"
    ToolTip.create :model => 'Node',
                   :attr=> 'used_space',
                   :description => 'Amount of disk space in use <br /><font size=-1 color=red>** Disk space info only reflects<br />"/" and "/home</font>'
    ToolTip.create :model => 'Node',
                   :attr=> 'avail_space',
                   :description => 'Amount of disk space available <br /><font size=-1 color=red>** Disk space info only reflects<br />"/" and "/home</font>'
    ToolTip.create :model => 'Node',
                   :attr=> 'os_processor_count',
                   :description => 'Number of <font color=red>physical</font> processors seen by the OS'
    ToolTip.create :model => 'Node',
                   :attr=> 'os_virtual_processor_count',
                   :description => 'Number of <font color=red>all</font> processors seen by the OS'
    ToolTip.create :model => 'Node',
                   :attr=> 'os_virtual_processor_count',
                   :description => 'Number of <font color=red>all</font> processors seen by the OS'
    ToolTip.create :model => 'Node',
                   :attr=> 'network_interfaces',
                   :description => 'Network interfaces such as ethernet or fiber, belonging to a node'

  end

  def self.down
    drop_table :tool_tips
  end

end
