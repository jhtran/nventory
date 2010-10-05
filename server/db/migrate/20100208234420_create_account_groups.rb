class CreateAccountGroups < ActiveRecord::Migration
  def self.up
    create_table :account_groups do |t|
      t.column	:name,	:string, :null => false
      t.column  :description,	:string
      t.integer :slfgrp
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
      t.timestamps
    end
    add_index :account_groups, :name
    add_index :account_groups, :slfgrp
    Account.all.each do |user| 
      user.admin = false
      userag = AccountGroup.create({:name => "#{user.login}.self",:slfgrp => 1})
      user.authz = userag
      user.save
      userag.has_role 'updater', userag
      userag.has_role 'updater', user
      if user.login == 'autoreg'
        userag.has_role 'creator', Node 
        userag.has_role 'updater', Node 
      end
    end
    admins = AccountGroup.create({:name => 'Administrators'})
    admins.has_role 'admin'
  end

  def self.down
    drop_table :account_groups
  end
end
