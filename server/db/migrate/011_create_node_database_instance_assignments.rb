class CreateNodeDatabaseInstanceAssignments < ActiveRecord::Migration
  def self.up
    create_table :node_database_instance_assignments do |t|
      t.column :node_id,                :integer
      t.column :database_instance_id,   :integer
      t.column :assigned_at,            :datetime
      t.column :created_at,             :datetime
      t.column :updated_at,             :datetime
      t.column :deleted_at,             :datetime
    end
    add_index :node_database_instance_assignments, :id
    add_index :node_database_instance_assignments, :node_id
    add_index :node_database_instance_assignments, :database_instance_id
    add_index :node_database_instance_assignments, :assigned_at
    add_index :node_database_instance_assignments, :deleted_at
  end

  def self.down
    drop_table :node_database_instance_assignments
  end
end
