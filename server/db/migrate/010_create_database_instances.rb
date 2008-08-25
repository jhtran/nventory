class CreateDatabaseInstances < ActiveRecord::Migration
  def self.up
    create_table :database_instances do |t|
      t.column :name,            :string
      t.column :notes,           :text
      t.column :created_at,      :datetime
      t.column :updated_at,      :datetime
      t.column :deleted_at,      :datetime
    end
    add_index :database_instances, :id
    add_index :database_instances, :name
    add_index :database_instances, :deleted_at
  end

  def self.down
    drop_table :database_instances
  end
end
