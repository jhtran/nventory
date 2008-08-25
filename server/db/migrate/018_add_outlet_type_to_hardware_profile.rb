class AddOutletTypeToHardwareProfile < ActiveRecord::Migration
  def self.up
    add_column "hardware_profiles", "outlet_type", :string
  end

  def self.down
    remove_column "hardware_profiles", "outlet_type"
  end
end
