class CreateRacks < ActiveRecord::Migration
  def self.up
    create_table :racks do |t|
      t.column :name,       :string
      t.column :location,   :text
      t.column :notes,      :text
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
      t.column :deleted_at, :datetime
    end
    add_index :racks, :id
    add_index :racks, :name
    add_index :racks, :deleted_at
  end

  def self.down
    drop_table :racks
  end
  
end
