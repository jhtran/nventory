class CreateDrives < ActiveRecord::Migration
  def self.up
    create_table :drives do |t|
      t.column :name,             :string, :null => false
      t.column :storage_controller_id,          :integer
      t.column :logicalname,	  :string
      t.column :vendor,		  :string
      t.column :physid,		  :string
      t.column :businfo,	  :string
      t.column :handle,		  :string
      t.column :serial,		  :string
      t.column :description,	  :string
      t.column :product,	  :string
      t.column :vendor, 	  :string
      t.column :size,	 	  :integer, :limit => 8
      t.column :dev,	 	  :string
      t.column :created_at,       :datetime
      t.column :updated_at,       :datetime
    end
  end

  def self.down
    drop_table :drives
  end
end
