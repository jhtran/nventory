class AddVmDiskToNode < ActiveRecord::Migration
  def self.up
    # add a column to node so it can have a hardware profile
    add_column "nodes", "vmimg_size", :integer
    add_column "nodes", "vmspace_used", :integer
    add_column "nodes", "used_space", :integer
    add_column "nodes", "avail_space", :integer
  end

  def self.down
    remove_column "nodes", "vmimg_size"
    remove_column "nodes", "vmspace_used"
    remove_column "nodes", "used_space"
    remove_column "nodes", "avail_space"
  end
end
