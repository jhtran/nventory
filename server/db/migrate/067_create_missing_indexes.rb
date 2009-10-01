class CreateMissingIndexes < ActiveRecord::Migration
  def self.up
    [ :service_id, :dev_url, :qa_url, :stg_url, :prod_url, :repo_url, 
      :contact, :codelang, :external, :pciscope, :created_at, :updated_at ].each do |field|
      add_index :service_profiles, field
    end
    [ :volume_type, :configf, :volume_server_id ].each do |field|
      add_index :volumes, field
    end
    [ :vmimg_size, :vmspace_used, :used_space, :avail_space, :expiration, :virtualarch, 
       :virtual_parent_node_id, :timezone ].each do |field|
      add_index :nodes, field
    end
    [ :port, :lbmethod, :healthcheck, :created_at, :updated_at ].each do |field|
      add_index :lb_profiles, field
    end
    [ :load_balancer_id, :ip_address, :protocol, :port ].each do |field|
      add_index :vips, field
    end
    [ :source_type, :created_at, :updated_at ].each do |field|
      add_index :name_aliases, field
    end
    add_index :name_aliases, [:source_id, :name], :name => 'source_id_name'
    add_index :node_group_node_assignments, :virtual_assignment
    add_index :node_groups, :lb_profile_id
  end

  def self.down
  end
end
