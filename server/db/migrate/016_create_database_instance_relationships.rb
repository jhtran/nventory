class CreateDatabaseInstanceRelationships < ActiveRecord::Migration
  def self.up
    create_table :database_instance_relationships do |t|
      t.column :name,             :string
      t.column :from_id,          :integer
      t.column :to_id,            :integer
      t.column :assigned_at,      :datetime
      t.column :created_at,       :datetime
      t.column :updated_at,       :datetime
      t.column :deleted_at,       :datetime
    end
    add_index :database_instance_relationships, :id
    add_index :database_instance_relationships, :name
    add_index :database_instance_relationships, :from_id
    add_index :database_instance_relationships, :to_id
    add_index :database_instance_relationships, :assigned_at
    add_index :database_instance_relationships, :deleted_at
  end

  def self.down
    drop_table :database_instance_relationships
  end
end
