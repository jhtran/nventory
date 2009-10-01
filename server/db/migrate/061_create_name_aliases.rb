class CreateNameAliases < ActiveRecord::Migration
  def self.up
    create_table :name_aliases do |t|
      t.column :name,             :string
      t.column :source_id,      :integer
      t.column :source_type,      :string
      t.column :created_at,       :datetime
      t.column :updated_at,       :datetime
    end
    add_index :name_aliases, :id
    add_index :name_aliases, :name
    add_index :name_aliases, :source_id
  end

  def self.down
    drop_table :name_aliases
  end
end
