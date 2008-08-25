class AddAdditionalFieldsToHardwareProfile < ActiveRecord::Migration
  def self.up
    add_column "hardware_profiles", "model", :string

    add_column "hardware_profiles", "processor_manufacturer", :string
    rename_column "hardware_profiles", "processor_type", "processor_model"

    add_column "hardware_profiles", "processor_socket_count", :integer

    add_column "hardware_profiles", "power_supply_slot_count", :integer

    add_column "hardware_profiles", "power_consumption", :integer

    # Don't force bogus data into the database by having default
    # numeric values for these columns
    change_column "hardware_profiles", "rack_size",          :integer, :default => nil
    change_column "hardware_profiles", "nics",               :integer, :default => nil
    change_column "hardware_profiles", "processor_count",    :integer, :default => nil
    change_column "hardware_profiles", "outlet_count",       :integer, :default => nil
    change_column "hardware_profiles", "estimated_cost",     :integer, :default => nil
    change_column "hardware_profiles", "power_supply_count", :integer, :default => nil

    rename_column "hardware_profiles", "notes", "description"
  end

  def self.down
    remove_column "hardware_profiles", "model"

    remove_column "hardware_profiles", "processor_manufacturer"
    rename_column "hardware_profiles", "processor_model", "processor_type"

    remove_column "hardware_profiles", "processor_socket_count"

    remove_column "hardware_profiles", "power_supply_slot_count"

    remove_column "hardware_profiles", "power_consumption"

    rename_column "hardware_profiles", "description", "notes"
  end
end
