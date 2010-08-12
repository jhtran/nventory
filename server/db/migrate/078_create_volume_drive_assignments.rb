class CreateVolumeDriveAssignments < ActiveRecord::Migration
  def self.up
    create_table :volume_drive_assignments do |t|
      t.column :volume_id,          :integer, :null => false
      t.column :drive_id,    :integer, :null => false
      t.column :assigned_at,      :datetime
      t.column :created_at,       :datetime
      t.column :updated_at,       :datetime
    end
    # According to the "Agile Web Development with Rails" book the first
    # index should also serve as an index for queries based on just
    # vip_id
    add_index :volume_drive_assignments, :volume_id
    add_index :volume_drive_assignments, :drive_id
    add_index :volume_drive_assignments, :assigned_at
  end

  def self.down
    drop_table :volume_drive_assignments
  end
end
