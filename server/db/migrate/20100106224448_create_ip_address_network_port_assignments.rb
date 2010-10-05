class CreateIpAddressNetworkPortAssignments < ActiveRecord::Migration
  def self.up
    create_table :ip_address_network_port_assignments do |t|
      t.column :ip_address_id, 	  :integer
      t.column :network_port_id,  :integer
      t.column :apps,             :string
      t.column :created_at,       :datetime
      t.column :updated_at,       :datetime
      t.column :assigned_at,      :datetime
      t.column :nmap_first_seen_at,  :datetime
      t.column :nmap_last_seen_at,  :datetime
      t.timestamps
    end
  end

  def self.down
    drop_table :ip_address_network_port_assignments
  end
end
