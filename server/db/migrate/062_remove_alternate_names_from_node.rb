class RemoveAlternateNamesFromNode < ActiveRecord::Migration
  def self.up
    remove_column(Node,:alternate_names)
  end

  def self.down
    add_column(Node,:alternate_names)
  end
end
