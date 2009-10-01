class CreateVolumeNodeAssignments < ActiveRecord::Migration
  def self.up
    create_table :volume_node_assignments do |t|
      t.column :volume_id,          :integer
      t.column :node_id,          :integer
      t.column :mount,		  :string
      t.column :configf,	  :string
      t.column :assigned_at,      :datetime
      t.column :created_at,       :datetime
      t.column :updated_at,       :datetime
    end
    add_index :volume_node_assignments, :id
    add_index :volume_node_assignments, :node_id
    add_index :volume_node_assignments, :mount
    add_index :volume_node_assignments, :volume_id
    add_index :volume_node_assignments, :assigned_at
  end

  def self.down
    drop_table :volume_node_assignments
  end
end
