class AddAttrToRolesUser < ActiveRecord::Migration
  def self.up
    add_column 'roles_users', :attrs, :string
  end

  def self.down
    remove_column 'roles_users',:attrs
  end
end
