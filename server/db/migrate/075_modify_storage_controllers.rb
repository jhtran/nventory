class ModifyStorageControllers < ActiveRecord::Migration
  def self.up
    add_column :storage_controllers, :product, :string
    add_column :storage_controllers, :description, :string
    add_column :storage_controllers, :physid, :string
    add_column :storage_controllers, :vendor, :string
    add_column :storage_controllers, :handle, :string
    add_column :storage_controllers, :logicalname, :string
    rename_column :storage_controllers, :bus_interface, :businfo
    add_index :storage_controllers, :product
    add_index :storage_controllers, :description
    add_index :storage_controllers, :physid
    add_index :storage_controllers, :vendor
    add_index :storage_controllers, :handle
    add_index :storage_controllers, :logicalname
    remove_index :storage_controllers, :bus_interface
    add_index :storage_controllers, :businfo
  end

  def self.down
    remove_column :storage_controllers, :product
    remove_column :storage_controllers, :description
    remove_column :storage_controllers, :physid
    remove_column :storage_controllers, :vendor
    remove_column :storage_controllers, :handle
    remove_column :storage_controllers, :logicalname
    rename_column :storage_controllers, :businfo, :bus_interface;
    add_index :storage_controllers, :bus_interface
  end
end
