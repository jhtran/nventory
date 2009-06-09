class CreateLbProfiles< ActiveRecord::Migration
  def self.up
    create_table :lb_profiles do |t|
      t.column :protocol,	:string
      t.column :port,		:string
      t.column :lbmethod,	:string
      t.column :healthcheck,	:string
      t.column :created_at,	:datetime
      t.column :updated_at,	:datetime
    end
    add_index :lb_profiles, :id
    # Add the default profile
    LbProfile.reset_column_information
    LbProfile.create :protocol => 'tcp',
                     :port => 80,
                     :lbmethod => 'round_robin',
                     :healthcheck => 'http'
  end

  def self.down
    drop_table :lb_profiles
  end
end
