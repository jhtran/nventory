class AddAssetTagAndAlternateNamesToNodes < ActiveRecord::Migration
  def self.up
    add_column "nodes", "asset_tag", :string
    add_column "nodes", "alternate_names", :string
  end

  def self.down
    remove_column "nodes", "asset_tag"
    remove_column "nodes", "alternate_names"
  end
end
