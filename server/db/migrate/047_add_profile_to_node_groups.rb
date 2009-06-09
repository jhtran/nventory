class AddProfileToNodeGroups < ActiveRecord::Migration
  def self.up
    add_column :node_groups, :lb_profile_id, :integer
  end

  def self.down
    remove_column :node_groups, :lb_profile_id
  end
end
