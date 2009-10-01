class CreateStorageControllers < ActiveRecord::Migration
  def self.up
    create_table :storage_controllers do |t|
      t.column :name,             :string, :null => false
      t.column :controller_type,  :string
      t.column :physical,         :boolean
      t.column :bus_interface,    :string
      t.column :slot,             :string
      t.column :firmware,         :string
      t.column :cache_size,       :integer
      t.column :batteries,        :integer
      t.column :node_id,          :integer
      t.column :created_at,       :datetime
      t.column :updated_at,       :datetime
    end
    add_index :storage_controllers, :name
    add_index :storage_controllers, :controller_type
    add_index :storage_controllers, :physical
    add_index :storage_controllers, :bus_interface
    add_index :storage_controllers, :slot
    add_index :storage_controllers, :firmware
    add_index :storage_controllers, :cache_size
    add_index :storage_controllers, :batteries
    add_index :storage_controllers, :node_id
    add_index :storage_controllers, :created_at
    add_index :storage_controllers, :updated_at
  end

  def self.down
    drop_table :storage_controllers
  end
end
