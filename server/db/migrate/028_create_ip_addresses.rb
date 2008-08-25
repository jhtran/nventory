class CreateIpAddresses < ActiveRecord::Migration
  def self.up
    create_table :ip_addresses do |t|
      t.column :network_interface_id,  :integer
      t.column :address,               :string, :null => false
      t.column :address_type,          :string, :null => false
      t.column :netmask,               :string
      t.column :broadcast,             :string
      t.column :created_at,            :datetime
      t.column :updated_at,            :datetime
      t.column :deleted_at,            :datetime
    end
    add_index :ip_addresses, :address
    add_index :ip_addresses, :network_interface_id
    add_index :ip_addresses, :deleted_at
  end

  def self.down
    drop_table :ip_addresses
  end
end
