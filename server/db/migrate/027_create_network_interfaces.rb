class CreateNetworkInterfaces < ActiveRecord::Migration
  def self.up
    create_table :network_interfaces do |t|
      t.column :name,             :string, :null => false
      # Can't use just 'type', as that is the column name Rails uses for
      # Single Table Inheritance
      t.column :interface_type,   :string
      t.column :physical,         :boolean
      t.column :hardware_address, :string
      t.column :up,               :boolean
      t.column :link,             :boolean
      t.column :speed,            :integer
      t.column :full_duplex,      :boolean
      t.column :autonegotiate,    :boolean
      t.column :node_id,          :integer
      t.column :created_at,       :datetime
      t.column :updated_at,       :datetime
      t.column :deleted_at,       :datetime
    end
    add_index :network_interfaces, :name
    add_index :network_interfaces, :node_id
    add_index :network_interfaces, :deleted_at
  end

  def self.down
    drop_table :network_interfaces
  end
end
