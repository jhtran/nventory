class CreateHardwareProfiles < ActiveRecord::Migration
  def self.up
    create_table :hardware_profiles do |t|
      t.column :name,            :string
      t.column :manufacturer,    :string
      t.column :rack_size,       :integer, :default => 1
      t.column :memory,          :string
      t.column :disk,            :string
      t.column :nics,            :integer, :default => 0
      t.column :processor_type,  :string
      t.column :processor_speed, :string
      t.column :processor_count, :integer, :default => 0
      t.column :cards,           :string
      t.column :notes,           :text
      t.column :outlet_count,    :integer, :default => 0
      t.column :estimated_cost,  :integer, :default => 0
      t.column :created_at,      :datetime
      t.column :updated_at,      :datetime
      t.column :deleted_at,      :datetime
    end
    add_index :hardware_profiles, :id
    add_index :hardware_profiles, :name
    add_index :hardware_profiles, :deleted_at
    
    # add a column to node so it can have a hardware profile
    add_column "nodes", "hardware_profile_id", :integer
    
    add_index :nodes, :hardware_profile_id
    
  end

  def self.down
    drop_table :hardware_profiles
    remove_column "nodes", "hardware_profile_id"
  end
end
