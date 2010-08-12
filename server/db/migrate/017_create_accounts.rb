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
    end
    add_index :accounts, :id
    add_index :accounts, :name
  end

  def self.down
    drop_table :accounts
  end
end
