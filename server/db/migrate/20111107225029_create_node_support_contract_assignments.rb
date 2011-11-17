class CreateNodeSupportContractAssignments < ActiveRecord::Migration
  def self.up
    create_table :node_support_contract_assignments do |t|
      t.column :node_id,                :integer, :null => false
      t.column :support_contract_id,    :integer, :null => false
      t.column :assigned_at,      :datetime
      t.timestamp
    end
  end

  def self.down
    drop_table :node_support_contract_assignments
  end
end
