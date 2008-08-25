class CreateOperatingSystems < ActiveRecord::Migration
  def self.up
    create_table :operating_systems do |t|
      t.column :name,            :string
      t.column :vendor,          :string
      t.column :variant,         :string
      t.column :version_number,  :string
      t.column :created_at,      :datetime
      t.column :updated_at,      :datetime
      t.column :deleted_at,      :datetime
    end
    add_index :operating_systems, :id
    add_index :operating_systems, :name
    add_index :operating_systems, :deleted_at
    
    # add a column to node so it can have a operating system
    add_column "nodes", "operating_system_id", :integer
    
  end

  def self.down
    drop_table :operating_systems
    remove_column "nodes", "operating_system_id"
  end
end
