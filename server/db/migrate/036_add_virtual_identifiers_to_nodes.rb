class AddVirtualIdentifiersToNodes < ActiveRecord::Migration
  def self.up
    add_column :nodes, :virtual_client_ids, :text
    add_column :nodes, :virtual_parent_node_id, :integer
  end

  def self.down
    remove_column :nodes, :virtual_client_ids
    remove_column :nodes, :virtual_parent_node_id
  end
end
