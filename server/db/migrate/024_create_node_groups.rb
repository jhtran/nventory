class CreateNodeGroups < ActiveRecord::Migration
  def self.up
    create_table :node_groups do |t|
      t.column :name,           :string, :null => false
      t.column :description,    :text
      t.column :created_at,     :datetime
      t.column :updated_at,     :datetime
      t.column :deleted_at,     :datetime
    end
    add_index :node_groups, :name, :unique => true
    add_index :node_groups, :deleted_at
  end

  def self.down
    drop_table :node_groups
  end
end
