class CreateDatacenters < ActiveRecord::Migration
  def self.up
    create_table :datacenters do |t|
      t.column :name,                 :string
      t.column :physical_address,     :text
      t.column :shipping_address,     :text
      t.column :manager,              :string
      t.column :support_phone_number, :string
      t.column :support_email,        :string
      t.column :support_url,          :string
      t.column :created_at,           :datetime
      t.column :updated_at,           :datetime
      t.column :deleted_at,           :datetime
    end
    add_index :datacenters, :id 
    add_index :datacenters, :name 
    add_index :datacenters, :deleted_at 
  end

  def self.down
    drop_table :datacenters
  end
end
