class CreateRoles < ActiveRecord::Migration

  def self.up
    create_table :roles_users, :force => true  do |t|
      t.integer :account_group_id, :role_id
      t.timestamps
    end

    create_table :roles, :force => true do |t|
      t.string  :name, :authorizable_type, :limit => 40
      t.integer :authorizable_id
      t.timestamps
    end
    add_index :roles_users, :account_group_id
    add_index :roles, :name
    add_index :roles, :authorizable_id
    admin = Account.find_by_login('admin')
  end

  def self.down
    drop_table :roles
    drop_table :roles_users
  end

end
