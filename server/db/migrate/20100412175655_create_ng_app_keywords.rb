class CreateNgAppKeywords < ActiveRecord::Migration
  def self.up
    create_table :ng_app_keywords do |t|
      t.column :name,       :string
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end
    add_index :ng_app_keywords, :id
    add_index :ng_app_keywords, :name
  end

  def self.down
    drop_table :ng_app_keywords
  end
end
