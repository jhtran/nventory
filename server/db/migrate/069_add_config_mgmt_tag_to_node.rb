class AddConfigMgmtTagToNode < ActiveRecord::Migration
  def self.up
    add_column :nodes, :config_mgmt_tag, :string
    add_index :nodes, :config_mgmt_tag
  end

  def self.down
    remove_column :nodes, :config_mgmt_tag
  end
end
