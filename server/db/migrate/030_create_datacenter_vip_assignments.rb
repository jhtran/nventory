class CreateDatacenterVipAssignments < ActiveRecord::Migration
  def self.up
    create_table :datacenter_vip_assignments do |t|
      t.column :datacenter_id,    :integer, :null => false
      t.column :vip_id,           :integer, :null => false
      t.column :priority,         :integer
      t.column :assigned_at,      :datetime
      t.column :created_at,       :datetime
      t.column :updated_at,       :datetime
      t.column :deleted_at,       :datetime
    end
    # According to the "Agile Web Development with Rails" book the first
    # index should also serve as an index for queries based on just
    # node_id
    add_index :datacenter_vip_assignments, [:datacenter_id, :vip_id]
    add_index :datacenter_vip_assignments, :vip_id
    add_index :datacenter_vip_assignments, :assigned_at
    add_index :datacenter_vip_assignments, :deleted_at
  end

  def self.down
    drop_table :datacenter_vip_assignments
  end
end
