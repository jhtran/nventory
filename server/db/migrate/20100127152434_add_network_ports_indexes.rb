class AddNetworkPortsIndexes < ActiveRecord::Migration
  def self.up
    add_index :network_ports, :protocol
    add_index :network_ports, :number
    add_index :network_ports, :created_at
    add_index :network_ports, :updated_at
    add_index :ip_address_network_port_assignments, :ip_address_id
    add_index :ip_address_network_port_assignments, :network_port_id
    add_index :ip_address_network_port_assignments, :apps
    add_index :ip_address_network_port_assignments, :created_at
    add_index :ip_address_network_port_assignments, :updated_at
    add_index :ip_address_network_port_assignments, :nmap_first_seen_at
    add_index :ip_address_network_port_assignments, :nmap_last_seen_at
  end

  def self.down
    remove_index :network_ports, :protocol
    remove_index :network_ports, :number
    remove_index :network_ports, :created_at
    remove_index :network_ports, :updated_at
    remove_index :ip_removeress_network_port_assignments, :ip_removeress_id
    remove_index :ip_removeress_network_port_assignments, :network_port_id
    remove_index :ip_removeress_network_port_assignments, :apps
    remove_index :ip_removeress_network_port_assignments, :created_at
    remove_index :ip_removeress_network_port_assignments, :updated_at
    remove_index :ip_removeress_network_port_assignments, :nmap_first_seen_at
    remove_index :ip_removeress_network_port_assignments, :nmap_last_seen_at
  end
end
