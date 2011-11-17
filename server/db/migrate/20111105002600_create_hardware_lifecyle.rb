class CreateHardwareLifecyle < ActiveRecord::Migration
  def self.up
    create_table :hardware_lifecycles do |t|
      t.column :node_id,                          :integer
      t.column :ship_date,                        :datetime
      t.column :out_of_service_date,              :datetime
      t.timestamps
    end
  end

  def self.down
    drop_table :hardware_lifecycles
  end
end
