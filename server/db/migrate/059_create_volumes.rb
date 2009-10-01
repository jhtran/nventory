class CreateVolumes < ActiveRecord::Migration
  def self.up
    create_table :volumes do |t|
      t.column :name,       :string
      t.column :volume_type,       :string
      t.column :configf,       :string
      t.column :volume_server_id, :integer
      t.column :description,      :text
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end
    add_index :volumes, :id
    add_index :volumes, :name
  end

  def self.down
    drop_table :volumes
  end
  
end
