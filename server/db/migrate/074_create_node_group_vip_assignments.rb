class CreateNodeGroupVipAssignments < ActiveRecord::Migration
  def self.up
    create_table :node_group_vip_assignments do |t|
      t.column :vip_id,          :integer, :null => false
      t.column :node_group_id,    :integer, :null => false
      t.column :virtual_assignment,	:boolean
      t.column :assigned_at,      :datetime
      t.column :created_at,       :datetime
      t.column :updated_at,       :datetime
      t.column :deleted_at,       :datetime
    end
    # According to the "Agile Web Development with Rails" book the first
    # index should also serve as an index for queries based on just
    # vip_id
    add_index :node_group_vip_assignments, [:vip_id, :node_group_id]
    add_index :node_group_vip_assignments, :node_group_id
    add_index :node_group_vip_assignments, :assigned_at
    add_index :node_group_vip_assignments, :deleted_at
    # add some new tooltips 
    ToolTip.create :model => 'Vip',
                   :attr=> 'lb_pools',
                   :description => 'Organizational unit which ties nodes to a VIP'
    ToolTip.create :model => 'Vip',
                   :attr=> 'load_balancer',
                   :description => 'Load Balancer transparently redirects incoming HTTP requests from Web clients to a set of Web servers.'
    ToolTip.create :model => 'VipLbPoolAssignment',
                   :attr=> 'vip',
                   :description => 'Virtual IP – an IP address that is shared among multiple domain names or multiple servers. A virtual IP address eliminates a host’s dependency upon individual network interfaces. Incoming packets are sent to the system’s VIP address, but all packets travel through the real network interfaces.

A VIP can belong to a load balancing device such as F5 BigIP or can be a clustered VIP such as that used in RedHat Cluster or Windows Load Balancing Service.'
  end

  def self.down
    drop_table :node_group_vip_assignments
  end
end
