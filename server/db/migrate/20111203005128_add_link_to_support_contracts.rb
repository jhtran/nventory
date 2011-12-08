class AddLinkToSupportContracts < ActiveRecord::Migration
  def self.up
    add_column 'support_contracts', :link, :text
  end

  def self.down
    remove_column 'support_contracts', :link
  end
end
