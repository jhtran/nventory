class CreateStatuses < ActiveRecord::Migration
  def self.up
    create_table :statuses do |t|
      t.column :name,            :string
      t.column :notes,           :text
      t.column :created_at,      :datetime
      t.column :updated_at,      :datetime
      t.column :deleted_at,      :datetime
    end
    add_index :statuses, :id
    add_index :statuses, :name
    add_index :statuses, :deleted_at
    
    # add a column to node so it can have a status
    add_column "nodes", "status_id", :integer
    add_index :nodes, :status_id

    # Some System Install Defaults
    s1 = Status.new
    s1.name = 'inservice'
    s1.notes = 'Hardware and OS functional, applications running'
    s1.save
    s2 = Status.new
    s2.name = 'outofservice'
    s2.notes = 'Hardware and OS functional, applications not running'
    s2.save
    s3 = Status.new
    s3.name = 'available'
    s3.notes = 'Hardware functional, no applications assigned'
    s3.save
    s4 = Status.new
    s4.name = 'broken'
    s4.notes = 'Hardware or OS not functional'
    s4.save
    s5 = Status.new
    s5.name = 'setup'
    s5.notes = 'New node, not yet configured'
    s5.save
  end

  def self.down
    drop_table :statuses
    remove_column "nodes", "status_id"
  end
end
