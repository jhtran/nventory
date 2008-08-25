class AddTimezoneToNodes < ActiveRecord::Migration
  def self.up
    add_column :nodes, :timezone, :string
  end

  def self.down
    remove_column :nodes, :timezone
  end
end
