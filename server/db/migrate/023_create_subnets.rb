class CreateSubnets < ActiveRecord::Migration
  def self.up
    create_table :subnets do |t|
      t.column :network,        :string, :null => false
      t.column :netmask,        :string, :null => false
      t.column :gateway,        :string, :null => false
      t.column :broadcast,      :string, :null => false
      t.column :resolvers,      :string
      t.column :node_group_id,  :integer
      t.column :description,    :text
      t.column :created_at,     :datetime
      t.column :updated_at,     :datetime
      t.column :deleted_at,     :datetime
    end
    add_index :subnets, :network, :unique => true
    add_index :subnets, :node_group_id
    add_index :subnets, :deleted_at
  end

  def self.down
    drop_table :subnets
  end
end
