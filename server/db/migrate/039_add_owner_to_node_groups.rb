class AddOwnerToNodeGroups < ActiveRecord::Migration
  def self.up
    add_column "node_groups", "owner", :string
    add_index :node_groups, :owner
  end

  def self.down
    remove_column "node_groups", "owner"
  end
end
