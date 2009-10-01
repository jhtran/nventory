class RemoveLegacyVirtualColumnsFromNode < ActiveRecord::Migration
  def self.up
    remove_column :nodes, :virtual_client_ids
    remove_column :nodes, :virtual_parent_node_id
  end
  def self.down
  end
end
