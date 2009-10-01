class ChangeLbProfile < ActiveRecord::Migration
  def self.up
    remove_column :node_groups, :lb_profile_id
    add_column :lb_profiles, :lb_pool_id, :integer
  end
  def self.down
    add_column :node_groups, :lb_profile_id, :integer
    remove_column :lb_profiles, :lb_pool_id
  end
end
