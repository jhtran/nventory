class CreateNodes < ActiveRecord::Migration
  def self.up
    create_table :nodes do |t|
      t.column :name,          :string
      t.column :serial_number, :string
      t.column :created_at,    :datetime
      t.column :updated_at,    :datetime
      t.column :deleted_at,    :datetime
    end
    add_index :nodes, :id
    add_index :nodes, :name
    add_index :nodes, :serial_number
    add_index :nodes, :deleted_at
  end

  def self.down
    drop_table :nodes
  end
end
