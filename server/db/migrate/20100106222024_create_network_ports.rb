class CreateNetworkPorts < ActiveRecord::Migration
  def self.up
    create_table :network_ports do |t|
      t.column :protocol,         :string, :null => false
      t.column :number,           :integer, :null => false
      t.column :created_at,       :datetime
      t.column :updated_at,       :datetime
    end
  end

  def self.down
    drop_table :network_ports
  end
end
