class AddUHeightToNodeRack < ActiveRecord::Migration
  def self.up
    add_column 'node_racks', :u_height, :integer, :default => 42
  end

  def self.down
    drop_column 'node_racks', :u_height
  end
end
