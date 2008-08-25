class AddAdditionalFieldsToOperatingSystem < ActiveRecord::Migration
  def self.up
    add_column "operating_systems", "architecture", :string

    add_column "operating_systems", "description", :text
  end

  def self.down
    remove_column "operating_systems", "architecture"

    remove_column "operating_systems", "description"
  end
end
