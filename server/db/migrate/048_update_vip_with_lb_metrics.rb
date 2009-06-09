class UpdateVipWithLbMetrics < ActiveRecord::Migration
  def self.up
    remove_column :vips, :node_group_id
    add_column :vips, :load_balancer_id, :integer
    add_column :vips, :ip_address, :string
    add_column :vips, :protocol, :string
    add_column :vips, :port, :integer
  end

  def self.down
    add_column :vips, :node_group_id, :integer
    remove_column :vips, :load_balancer_id
    remove_column :vips, :ip_address
    remove_column :vips, :protocol
    remove_column :vips, :port
  end
end
