class CreateVips < ActiveRecord::Migration
  def self.up
    create_table :vips do |t|
      t.column :name,             :string, :null => false
      t.column :node_group_id,    :integer
      t.column :description,      :text
      t.column :created_at,       :datetime
      t.column :updated_at,       :datetime
      t.column :deleted_at,       :datetime
    end
    add_index :vips, :name, :unique => true
    add_index :vips, :node_group_id
    add_index :vips, :deleted_at
  end

  def self.down
    drop_table :vips
  end
end
