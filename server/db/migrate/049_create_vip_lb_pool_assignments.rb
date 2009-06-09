class CreateVipLbPoolAssignments < ActiveRecord::Migration
  def self.up
    create_table :vip_lb_pool_assignments do |t|
      t.column :vip_id,        :integer, :null => false
      t.column :lb_pool_id,         :integer, :null => false
      t.column :assigned_at,      :datetime
      t.column :created_at,       :datetime
      t.column :updated_at,       :datetime
    end
    # According to the "Agile Web Development with Rails" book the first
    # index should also serve as an index for queries based on just
    # vip_id
    #  The index name Rails picks is too long (MySQL rejects it)
    add_index :vip_lb_pool_assignments, [:vip_id, :lb_pool_id], :name => 'vip_lb_pool_index'
    add_index :vip_lb_pool_assignments, :lb_pool_id , :name => 'lb_pool_index'
    add_index :vip_lb_pool_assignments, :assigned_at, :name => 'assigned_at_index'
  end

  def self.down
    drop_table :vip_lb_pool_assignments
  end
end
