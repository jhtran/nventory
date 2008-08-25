class CreateDatacenterRackAssignments < ActiveRecord::Migration
  def self.up
    create_table :datacenter_rack_assignments do |t|
      t.column :datacenter_id,    :integer
      t.column :rack_id,          :integer
      t.column :assigned_at,      :datetime
      t.column :created_at,       :datetime
      t.column :updated_at,       :datetime
      t.column :deleted_at,       :datetime
    end
    add_index :datacenter_rack_assignments, :id
    add_index :datacenter_rack_assignments, :datacenter_id
    add_index :datacenter_rack_assignments, :rack_id
    add_index :datacenter_rack_assignments, :assigned_at
    add_index :datacenter_rack_assignments, :deleted_at
  end

  def self.down
    drop_table :datacenter_rack_assignments
  end
  
end
