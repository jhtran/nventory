class CreateAccounts < ActiveRecord::Migration
  def self.up
    create_table :accounts do |t|
      t.column :name,              :string
      t.column :login,             :string
      t.column :password_hash,     :string
      t.column :password_salt,     :string
      t.column :email_address,     :string
      t.column :admin,             :bool, :default => false
      t.column :created_at,        :datetime
      t.column :updated_at,        :datetime
      t.column :deleted_at,        :datetime
    end
    add_index :accounts, :id
    add_index :accounts, :name
    add_index :accounts, :deleted_at
    
    # Some System Install Defaults
    Account.create(:name => 'admin', :login => 'admin', :password => 'admin', :email_address => 'admin@example.com', :admin => true)
    Account.create(:name => 'autoreg', :login => 'autoreg', :password => 'autoreg', :email_address => 'autoreg@example.com', :admin => true)
    
  end

  def self.down
    drop_table :accounts
  end
end
