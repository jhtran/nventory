class CreateAccountGroupAccountGroupAssignments < ActiveRecord::Migration
  def self.up
    create_table :account_group_account_group_assignments do |t|
      t.column :parent_id,        :integer, :null => false
      t.column :child_id,         :integer, :null => false
      t.column :assigned_at,      :datetime
      t.column :created_at,       :datetime
      t.column :updated_at,       :datetime
    end
    add_index :account_group_account_group_assignments, [:parent_id, :child_id], :name => 'parent_child_index'
    add_index :account_group_account_group_assignments, :child_id 
    add_index :account_group_account_group_assignments, :assigned_at
  end

  def self.down
    drop_table :account_group_account_group_assignments
  end
end
