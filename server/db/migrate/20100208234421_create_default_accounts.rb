class CreateDefaultAccounts < ActiveRecord::Migration
  def self.up
    # Some System Install Defaults
    Account.create(:name => 'admin', :login => 'admin', :password => 'admin', :email_address => 'admin@domain.com', :admin => true)
    Account.create(:name => 'autoreg', :login => 'autoreg', :password => 'autoreg', :email_address => 'autoreg@domain.com', :admin => true)
    admin = Account.find_by_login('admin')
    admin.authz.has_role 'admin'
  end

  def self.down
    Account.find_by_login('admin').destroy
    Account.find_by_login('autoreg').destroy
  end
end


