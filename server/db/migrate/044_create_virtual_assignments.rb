class CreateVirtualAssignments < ActiveRecord::Migration
  def self.up
    create_table :virtual_assignments do |t|
      t.column :parent_id,        :integer, :null => false
      t.column :child_id,         :integer, :null => false
      t.column :assigned_at,      :datetime
      t.column :created_at,       :datetime
      t.column :updated_at,       :datetime
      t.column :deleted_at,       :datetime
    end
    # According to the "Agile Web Development with Rails" book the first
    # index should also serve as an index for queries based on just
    # parent_id
    #  The index name Rails picks is too long (MySQL rejects it)
    add_index :virtual_assignments, [:parent_id, :child_id], :name => 'parent_child_index'
    add_index :virtual_assignments, :child_id , :name => 'child_index'
    add_index :virtual_assignments, :assigned_at, :name => 'assigned_at_index'
    add_index :virtual_assignments, :deleted_at, :name => 'deleted_at_index'

  end

  def self.down
    drop_table :virtual_assignments
  end
end
