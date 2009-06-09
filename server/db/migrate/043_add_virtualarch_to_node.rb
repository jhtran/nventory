class AddVirtualarchToNode < ActiveRecord::Migration
  def self.up
    # add a column to node so it can have a hardware profile
    add_column "nodes", "virtualarch", :string
  end

  def self.down
    remove_column "nodes", "virtualarch"
  end
end
