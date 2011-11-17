class CreateSupportContracts < ActiveRecord::Migration
  def self.up
    create_table :support_contracts do |t|
      t.column :name,              :string, :null => false
      t.column :service_level,              :string
      t.column :expiration,               :datetime
      t.timestamps
    end
  end

  def self.down
    drop_table :support_contracts
  end
end
