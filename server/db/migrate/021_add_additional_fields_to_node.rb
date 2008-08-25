class AddAdditionalFieldsToNode < ActiveRecord::Migration
  def self.up
    add_column "nodes", "processor_manufacturer", :string
    add_column "nodes", "processor_model", :string
    add_column "nodes", "processor_speed", :string
    add_column "nodes", "processor_socket_count", :integer
    add_column "nodes", "processor_count", :integer

    add_column "nodes", "physical_memory", :string
    add_column "nodes", "physical_memory_sizes", :string
    add_column "nodes", "os_memory", :string
    add_column "nodes", "swap", :string

    add_column "nodes", "power_supply_count", :integer

    add_column "nodes", "console_type", :string

    add_column "nodes", "uniqueid", :string
    add_index :nodes, :uniqueid

    add_column "nodes", "kernel_version", :string

    # Add an OS column to refer to our preferred OS in case this node is
    # (re)installed
    add_column "nodes", "preferred_operating_system_id", :integer

    add_column "nodes", "description", :text
  end

  def self.down
    remove_column "nodes", "processor_manufacturer"
    remove_column "nodes", "processor_model"
    remove_column "nodes", "processor_speed"
    remove_column "nodes", "processor_socket_count"
    remove_column "nodes", "processor_count"

    remove_column "nodes", "physical_memory"
    remove_column "nodes", "physical_memory_sizes"
    remove_column "nodes", "os_memory"
    remove_column "nodes", "swap"

    remove_column "nodes", "power_supply_count"

    remove_column "nodes", "console_type"

    remove_column "nodes", "uniqueid"

    remove_column "nodes", "kernel_version"

    remove_column "nodes", "preferred_operating_system_id"

    remove_column "nodes", "description"
  end
end
