class MigrateAdminAccounts < ActiveRecord::Migration
  def self.up
    admins = Account.find(:all, :conditions => 'admin = 1')
    admins.each{|acc| acc.authz.has_role 'admin'}
  end

  def self.down
  end
end
