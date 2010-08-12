class ModifyVolumes < ActiveRecord::Migration
  def self.up
    add_column :volumes, :capacity, :integer, :limit => 8
    add_column :volumes, :size, :integer, :limit => 8
    add_column :volumes, :vendor, :string
    add_column :volumes, :businfo, :string
    add_column :volumes, :serial, :string
    add_column :volumes, :physid, :string
    add_column :volumes, :dev, :string
    add_column :volumes, :logicalname, :string
    add_index :volumes, :capacity
    add_index :volumes, :size
    add_index :volumes, :vendor
    add_index :volumes, :businfo
    add_index :volumes, :serial
    add_index :volumes, :physid
    add_index :volumes, :dev
    add_index :volumes, :logicalname
  end

  def self.down
    remove_column :volumes, :capacity
    remove_column :volumes, :vendor
    remove_column :volumes, :businfo
    remove_column :volumes, :serial
    remove_column :volumes, :physid
    remove_column :volumes, :dev
    remove_column :volumes, :logicalname
    remove_column :volumes, :size
  end
end
