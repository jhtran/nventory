class AddOsVirtualProcessorCountToNode < ActiveRecord::Migration
  def self.up
    add_column :nodes, :os_virtual_processor_count, :integer
    add_index :nodes, :os_virtual_processor_count
  end

  def self.down
    remove_column :nodes, :os_virtual_processor_count
  end
end
