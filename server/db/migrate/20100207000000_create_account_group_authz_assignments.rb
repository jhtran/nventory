class CreateAccountGroupAuthzAssignments < ActiveRecord::Migration
  def self.up
    create_table :account_group_authz_assignments do |t|
      t.column :authz_id,        :integer, :null => false
      t.column :account_group_id, :integer, :null => false
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
      t.column :assigned_at, :datetime
      t.timestamps
    end
    add_index :account_group_authz_assignments, :authz_id
    add_index :account_group_authz_assignments, :account_group_id
  end

  def self.down
    drop_table :account_group_authz_assignments
  end
end
