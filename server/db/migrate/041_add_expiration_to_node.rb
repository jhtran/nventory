class AddExpirationToNode < ActiveRecord::Migration
  def self.up
    # add a column to node so it can have a hardware profile
    add_column "nodes", "expiration", :datetime
  end

  def self.down
    remove_column "nodes", "expiration"
  end
end
