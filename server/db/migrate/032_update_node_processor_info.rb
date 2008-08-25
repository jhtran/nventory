class UpdateNodeProcessorInfo < ActiveRecord::Migration
  def self.up
    add_column :nodes, :processor_core_count, :integer
    add_column :nodes, :os_processor_count, :integer
  end

  def self.down
    remove_column :nodes, :processor_core_count
    remove_column :nodes, :os_processor_count
  end
end
