class CreateAccountGroupSelfGroupAssignments < ActiveRecord::Migration
  def self.up
    create_table :account_group_self_group_assignments do |t|
      t.column :account_group_id,          :integer, :null => false
      t.column :self_group_id,    :integer, :null => false
      t.column :virtual_assignment,	  :boolean
      t.column :assigned_at,      :datetime
      t.column :created_at,       :datetime
      t.column :updated_at,       :datetime
    end
    # According to the "Agile Web Development with Rails" book the first
    # index should also serve as an index for queries based on just
    # node_id
    add_index :account_group_self_group_assignments, [:account_group_id, :self_group_id], :name => 'index_on_agsga_ag_sg'
    add_index :account_group_self_group_assignments, :account_group_id
    add_index :account_group_self_group_assignments, :self_group_id
    add_index :account_group_self_group_assignments, :virtual_assignment
  end

  def self.down
    drop_table :account_group_self_group_assignments
  end
end
