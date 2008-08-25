class ConvertRemainingNotes < ActiveRecord::Migration
  def self.up
    rename_column :database_instances, :notes, :description
    rename_column :racks, :notes, :description
    rename_column :statuses, :notes, :description
    # Table for acts_as_commentable
    create_table "comments", :force => true do |t|
      t.column "title", :string, :limit => 50, :default => ""
      t.column "comment", :text, :default => ""
      t.column "created_at", :datetime, :null => false
      t.column "commentable_id", :integer, :default => 0, :null => false
      t.column "commentable_type", :string, :limit => 15, :default => "", :null => false
      t.column "user_id", :integer, :default => 0, :null => false
    end
    add_index "comments", ["user_id"], :name => "fk_comments_user"
    add_index "comments", ["commentable_id", "commentable_type"]
  end

  def self.down
    rename_column :database_instances, :description, :notes
    rename_column :racks, :description, :notes
    rename_column :statuses, :description, :notes
    drop_table :comments
  end
end
