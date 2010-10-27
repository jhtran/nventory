class AlterVipNameUniqueness < ActiveRecord::Migration
  def self.up
    remove_index :vips, :name
    add_index :vips, :name
  end

  def self.down
    remove_index :vips, :name
    add_index :vips, :name, :unique => true
  end
end
