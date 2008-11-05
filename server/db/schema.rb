# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 56) do

# Could not dump table "accounts" because of following StandardError
#   Unknown type 'bool' for column 'admin'

  create_table "audits", :force => true do |t|
    t.integer  "auditable_id"
    t.string   "auditable_type"
    t.integer  "user_id"
    t.string   "user_type"
    t.string   "username"
    t.string   "action"
    t.text     "changes"
    t.integer  "version",        :default => 0
    t.datetime "created_at"
  end

  add_index "audits", ["created_at"], :name => "index_audits_on_created_at"
  add_index "audits", ["user_id", "user_type"], :name => "user_index"
  add_index "audits", ["auditable_id", "auditable_type"], :name => "auditable_index"

  create_table "comments", :force => true do |t|
    t.string   "title",            :limit => 50, :default => ""
    t.text     "comment",                        :default => ""
    t.datetime "created_at",                                     :null => false
    t.integer  "commentable_id",                 :default => 0,  :null => false
    t.string   "commentable_type", :limit => 15, :default => "", :null => false
    t.integer  "user_id",                        :default => 0,  :null => false
  end

  add_index "comments", ["commentable_id", "commentable_type"], :name => "index_comments_on_commentable_id_and_commentable_type"
  add_index "comments", ["user_id"], :name => "fk_comments_user"

  create_table "database_instance_relationships", :force => true do |t|
    t.string   "name"
    t.integer  "from_id"
    t.integer  "to_id"
    t.datetime "assigned_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  add_index "database_instance_relationships", ["deleted_at"], :name => "index_database_instance_relationships_on_deleted_at"
  add_index "database_instance_relationships", ["assigned_at"], :name => "index_database_instance_relationships_on_assigned_at"
  add_index "database_instance_relationships", ["to_id"], :name => "index_database_instance_relationships_on_to_id"
  add_index "database_instance_relationships", ["from_id"], :name => "index_database_instance_relationships_on_from_id"
  add_index "database_instance_relationships", ["name"], :name => "index_database_instance_relationships_on_name"
  add_index "database_instance_relationships", ["id"], :name => "index_database_instance_relationships_on_id"

  create_table "database_instances", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  add_index "database_instances", ["deleted_at"], :name => "index_database_instances_on_deleted_at"
  add_index "database_instances", ["name"], :name => "index_database_instances_on_name"
  add_index "database_instances", ["id"], :name => "index_database_instances_on_id"

  create_table "datacenter_rack_assignments", :force => true do |t|
    t.integer  "datacenter_id"
    t.integer  "rack_id"
    t.datetime "assigned_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  add_index "datacenter_rack_assignments", ["deleted_at"], :name => "index_datacenter_rack_assignments_on_deleted_at"
  add_index "datacenter_rack_assignments", ["assigned_at"], :name => "index_datacenter_rack_assignments_on_assigned_at"
  add_index "datacenter_rack_assignments", ["rack_id"], :name => "index_datacenter_rack_assignments_on_rack_id"
  add_index "datacenter_rack_assignments", ["datacenter_id"], :name => "index_datacenter_rack_assignments_on_datacenter_id"
  add_index "datacenter_rack_assignments", ["id"], :name => "index_datacenter_rack_assignments_on_id"

  create_table "datacenter_vip_assignments", :force => true do |t|
    t.integer  "datacenter_id", :null => false
    t.integer  "vip_id",        :null => false
    t.integer  "priority"
    t.datetime "assigned_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  add_index "datacenter_vip_assignments", ["deleted_at"], :name => "index_datacenter_vip_assignments_on_deleted_at"
  add_index "datacenter_vip_assignments", ["assigned_at"], :name => "index_datacenter_vip_assignments_on_assigned_at"
  add_index "datacenter_vip_assignments", ["vip_id"], :name => "index_datacenter_vip_assignments_on_vip_id"
  add_index "datacenter_vip_assignments", ["datacenter_id", "vip_id"], :name => "index_datacenter_vip_assignments_on_datacenter_id_and_vip_id"

  create_table "datacenters", :force => true do |t|
    t.string   "name"
    t.text     "physical_address"
    t.text     "shipping_address"
    t.string   "manager"
    t.string   "support_phone_number"
    t.string   "support_email"
    t.string   "support_url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  add_index "datacenters", ["deleted_at"], :name => "index_datacenters_on_deleted_at"
  add_index "datacenters", ["name"], :name => "index_datacenters_on_name"
  add_index "datacenters", ["id"], :name => "index_datacenters_on_id"

  create_table "hardware_profiles", :force => true do |t|
    t.string   "name"
    t.string   "manufacturer"
    t.integer  "rack_size"
    t.string   "memory"
    t.string   "disk"
    t.integer  "nics"
    t.string   "processor_model"
    t.string   "processor_speed"
    t.integer  "processor_count"
    t.string   "cards"
    t.text     "description"
    t.integer  "outlet_count"
    t.integer  "estimated_cost"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.string   "visualization_color",     :default => "red"
    t.string   "outlet_type"
    t.integer  "power_supply_count"
    t.string   "model"
    t.string   "processor_manufacturer"
    t.integer  "processor_socket_count"
    t.integer  "power_supply_slot_count"
    t.integer  "power_consumption"
  end

  add_index "hardware_profiles", ["deleted_at"], :name => "index_hardware_profiles_on_deleted_at"
  add_index "hardware_profiles", ["name"], :name => "index_hardware_profiles_on_name"
  add_index "hardware_profiles", ["id"], :name => "index_hardware_profiles_on_id"

  create_table "ip_addresses", :force => true do |t|
    t.integer  "network_interface_id"
    t.string   "address",              :null => false
    t.string   "address_type",         :null => false
    t.string   "netmask"
    t.string   "broadcast"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  add_index "ip_addresses", ["deleted_at"], :name => "index_ip_addresses_on_deleted_at"
  add_index "ip_addresses", ["network_interface_id"], :name => "index_ip_addresses_on_network_interface_id"
  add_index "ip_addresses", ["address"], :name => "index_ip_addresses_on_address"

  create_table "network_interfaces", :force => true do |t|
    t.string   "name",             :null => false
    t.string   "interface_type"
    t.boolean  "physical"
    t.string   "hardware_address"
    t.boolean  "up"
    t.boolean  "link"
    t.integer  "speed"
    t.boolean  "full_duplex"
    t.boolean  "autonegotiate"
    t.integer  "node_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  add_index "network_interfaces", ["deleted_at"], :name => "index_network_interfaces_on_deleted_at"
  add_index "network_interfaces", ["node_id"], :name => "index_network_interfaces_on_node_id"
  add_index "network_interfaces", ["name"], :name => "index_network_interfaces_on_name"

  create_table "node_database_instance_assignments", :force => true do |t|
    t.integer  "node_id"
    t.integer  "database_instance_id"
    t.datetime "assigned_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  add_index "node_database_instance_assignments", ["deleted_at"], :name => "index_node_database_instance_assignments_on_deleted_at"
  add_index "node_database_instance_assignments", ["assigned_at"], :name => "index_node_database_instance_assignments_on_assigned_at"
  add_index "node_database_instance_assignments", ["database_instance_id"], :name => "index_node_database_instance_assignments_on_database_instance_id"
  add_index "node_database_instance_assignments", ["node_id"], :name => "index_node_database_instance_assignments_on_node_id"
  add_index "node_database_instance_assignments", ["id"], :name => "index_node_database_instance_assignments_on_id"

  create_table "node_group_node_assignments", :force => true do |t|
    t.integer  "node_id",            :null => false
    t.integer  "node_group_id",      :null => false
    t.datetime "assigned_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.boolean  "virtual_assignment"
  end

  add_index "node_group_node_assignments", ["deleted_at"], :name => "index_node_group_node_assignments_on_deleted_at"
  add_index "node_group_node_assignments", ["assigned_at"], :name => "index_node_group_node_assignments_on_assigned_at"
  add_index "node_group_node_assignments", ["node_group_id"], :name => "index_node_group_node_assignments_on_node_group_id"
  add_index "node_group_node_assignments", ["node_id", "node_group_id"], :name => "index_node_group_node_assignments_on_node_id_and_node_group_id"

  create_table "node_group_node_group_assignments", :force => true do |t|
    t.integer  "parent_id",   :null => false
    t.integer  "child_id",    :null => false
    t.datetime "assigned_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  add_index "node_group_node_group_assignments", ["deleted_at"], :name => "index_node_group_node_group_assignments_on_deleted_at"
  add_index "node_group_node_group_assignments", ["assigned_at"], :name => "index_node_group_node_group_assignments_on_assigned_at"
  add_index "node_group_node_group_assignments", ["child_id"], :name => "index_node_group_node_group_assignments_on_child_id"
  add_index "node_group_node_group_assignments", ["parent_id", "child_id"], :name => "parent_child_index"

  create_table "node_groups", :force => true do |t|
    t.string   "name",        :null => false
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  add_index "node_groups", ["name"], :name => "index_node_groups_on_name", :unique => true
  add_index "node_groups", ["deleted_at"], :name => "index_node_groups_on_deleted_at"

  create_table "nodes", :force => true do |t|
    t.string   "name"
    t.string   "serial_number"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.integer  "hardware_profile_id"
    t.integer  "operating_system_id"
    t.integer  "status_id"
    t.string   "processor_manufacturer"
    t.string   "processor_model"
    t.string   "processor_speed"
    t.integer  "processor_socket_count"
    t.integer  "processor_count"
    t.string   "physical_memory"
    t.string   "physical_memory_sizes"
    t.string   "os_memory"
    t.string   "swap"
    t.integer  "power_supply_count"
    t.string   "console_type"
    t.string   "uniqueid"
    t.string   "kernel_version"
    t.integer  "preferred_operating_system_id"
    t.text     "description"
    t.integer  "processor_core_count"
    t.integer  "os_processor_count"
    t.string   "asset_tag"
    t.string   "alternate_names"
    t.string   "timezone"
    t.text     "virtual_client_ids"
    t.integer  "virtual_parent_node_id"
  end

  add_index "nodes", ["uniqueid"], :name => "index_nodes_on_uniqueid"
  add_index "nodes", ["status_id"], :name => "index_nodes_on_status_id"
  add_index "nodes", ["hardware_profile_id"], :name => "index_nodes_on_hardware_profile_id"
  add_index "nodes", ["deleted_at"], :name => "index_nodes_on_deleted_at"
  add_index "nodes", ["serial_number"], :name => "index_nodes_on_serial_number"
  add_index "nodes", ["name"], :name => "index_nodes_on_name"
  add_index "nodes", ["id"], :name => "index_nodes_on_id"

  create_table "operating_systems", :force => true do |t|
    t.string   "name"
    t.string   "vendor"
    t.string   "variant"
    t.string   "version_number"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.string   "architecture"
    t.text     "description"
  end

  add_index "operating_systems", ["deleted_at"], :name => "index_operating_systems_on_deleted_at"
  add_index "operating_systems", ["name"], :name => "index_operating_systems_on_name"
  add_index "operating_systems", ["id"], :name => "index_operating_systems_on_id"

  create_table "outlets", :force => true do |t|
    t.string   "name"
    t.integer  "producer_id"
    t.integer  "consumer_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  add_index "outlets", ["deleted_at"], :name => "index_outlets_on_deleted_at"
  add_index "outlets", ["consumer_id"], :name => "index_outlets_on_consumer_id"
  add_index "outlets", ["producer_id"], :name => "index_outlets_on_producer_id"
  add_index "outlets", ["name"], :name => "index_outlets_on_name"
  add_index "outlets", ["id"], :name => "index_outlets_on_id"

  create_table "rack_node_assignments", :force => true do |t|
    t.integer  "rack_id"
    t.integer  "node_id"
    t.integer  "position"
    t.datetime "assigned_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  add_index "rack_node_assignments", ["deleted_at"], :name => "index_rack_node_assignments_on_deleted_at"
  add_index "rack_node_assignments", ["assigned_at"], :name => "index_rack_node_assignments_on_assigned_at"
  add_index "rack_node_assignments", ["rack_id"], :name => "index_rack_node_assignments_on_rack_id"
  add_index "rack_node_assignments", ["node_id"], :name => "index_rack_node_assignments_on_node_id"
  add_index "rack_node_assignments", ["id"], :name => "index_rack_node_assignments_on_id"

  create_table "racks", :force => true do |t|
    t.string   "name"
    t.text     "location"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  add_index "racks", ["deleted_at"], :name => "index_racks_on_deleted_at"
  add_index "racks", ["name"], :name => "index_racks_on_name"
  add_index "racks", ["id"], :name => "index_racks_on_id"

  create_table "sessions", :force => true do |t|
    t.string   "session_id"
    t.text     "data"
    t.datetime "updated_at"
  end

  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"
  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"

  create_table "statuses", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  add_index "statuses", ["deleted_at"], :name => "index_statuses_on_deleted_at"
  add_index "statuses", ["name"], :name => "index_statuses_on_name"
  add_index "statuses", ["id"], :name => "index_statuses_on_id"

  create_table "subnets", :force => true do |t|
    t.string   "network",       :null => false
    t.string   "netmask",       :null => false
    t.string   "gateway"
    t.string   "broadcast",     :null => false
    t.integer  "node_group_id"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  add_index "subnets", ["network"], :name => "index_subnets_on_network", :unique => true
  add_index "subnets", ["deleted_at"], :name => "index_subnets_on_deleted_at"
  add_index "subnets", ["node_group_id"], :name => "index_subnets_on_node_group_id"

  create_table "vips", :force => true do |t|
    t.string   "name",          :null => false
    t.integer  "node_group_id"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  add_index "vips", ["name"], :name => "index_vips_on_name", :unique => true
  add_index "vips", ["deleted_at"], :name => "index_vips_on_deleted_at"
  add_index "vips", ["node_group_id"], :name => "index_vips_on_node_group_id"

end
