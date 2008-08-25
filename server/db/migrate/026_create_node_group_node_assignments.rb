class CreateNodeGroupNodeAssignments < ActiveRecord::Migration
  def self.up
    create_table :node_group_node_assignments do |t|
      t.column :node_id,          :integer, :null => false
      t.column :node_group_id,    :integer, :null => false
      t.column :assigned_at,      :datetime
      t.column :created_at,       :datetime
      t.column :updated_at,       :datetime
      t.column :deleted_at,       :datetime
    end
    # According to the "Agile Web Development with Rails" book the first
    # index should also serve as an index for queries based on just
    # node_id
    add_index :node_group_node_assignments, [:node_id, :node_group_id]
    add_index :node_group_node_assignments, :node_group_id
    add_index :node_group_node_assignments, :assigned_at
    add_index :node_group_node_assignments, :deleted_at
  end

  def self.down
    drop_table :node_group_node_assignments
  end
end
