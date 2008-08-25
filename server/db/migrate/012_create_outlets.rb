class CreateOutlets < ActiveRecord::Migration
  def self.up
    create_table :outlets do |t|
      t.column :name,             :string
      t.column :producer_id,      :integer
      t.column :consumer_id,      :integer
      t.column :created_at,       :datetime
      t.column :updated_at,       :datetime
      t.column :deleted_at,       :datetime
    end
    add_index :outlets, :id
    add_index :outlets, :name
    add_index :outlets, :producer_id
    add_index :outlets, :consumer_id
    add_index :outlets, :deleted_at
  end

  def self.down
    drop_table :outlets
  end
end
