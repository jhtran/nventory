class CreateRackNodeAssignments < ActiveRecord::Migration
  def self.up
    create_table :rack_node_assignments do |t|
      t.column :rack_id,          :integer
      t.column :node_id,          :integer
      t.column :position,         :integer
      t.column :assigned_at,      :datetime
      t.column :created_at,       :datetime
      t.column :updated_at,       :datetime
      t.column :deleted_at,       :datetime
    end
    add_index :rack_node_assignments, :id
    add_index :rack_node_assignments, :node_id
    add_index :rack_node_assignments, :rack_id
    add_index :rack_node_assignments, :assigned_at
    add_index :rack_node_assignments, :deleted_at
  end

  def self.down
    drop_table :rack_node_assignments
  end
end
