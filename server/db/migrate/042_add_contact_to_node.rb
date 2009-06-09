class AddContactToNode < ActiveRecord::Migration
  def self.up
    # add a column to node so it can have a hardware profile
    add_column "nodes", "contact", :text
  end

  def self.down
    remove_column "nodes", "contact"
  end
end
