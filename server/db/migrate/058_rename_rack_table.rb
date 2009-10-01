class RenameRackTable < ActiveRecord::Migration
  def self.up
    rename_table(:racks,:node_racks)
    rename_table(:rack_node_assignments,:node_rack_node_assignments)
    rename_table(:datacenter_rack_assignments,:datacenter_node_rack_assignments)
    rename_column(:datacenter_node_rack_assignments, :rack_id, :node_rack_id)
    rename_column(:node_rack_node_assignments, :rack_id, :node_rack_id)
  end

  def self.down
    rename_table(:node_racks,:racks)
    rename_table(:node_rack_node_assignments,:rack_node_assignments)
    rename_table(:datacenter_node_rack_assignments,:datacenter_rack_assignments)
    rename_column(:datacenter_rack_assignments, :node_rack_id, :rack_id)
    rename_column(:rack_node_assignments, :node_rack_id, :rack_id)
  end
end
