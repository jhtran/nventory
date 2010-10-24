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

ActiveRecord::Schema.define(:version => 20101014233527) do

  create_table "account_group_account_group_assignments", :force => true do |t|
    t.integer  "parent_id",   :null => false
    t.integer  "child_id",    :null => false
    t.datetime "assigned_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "account_group_account_group_assignments", ["assigned_at"], :name => "index_account_group_account_group_assignments_on_assigned_at"
  add_index "account_group_account_group_assignments", ["child_id"], :name => "index_account_group_account_group_assignments_on_child_id"
  add_index "account_group_account_group_assignments", ["parent_id", "child_id"], :name => "parent_child_index"

  create_table "account_group_authz_assignments", :force => true do |t|
    t.integer  "authz_id",         :null => false
    t.integer  "account_group_id", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "assigned_at"
  end

  add_index "account_group_authz_assignments", ["account_group_id"], :name => "index_account_group_authz_assignments_on_account_group_id"
  add_index "account_group_authz_assignments", ["authz_id"], :name => "index_account_group_authz_assignments_on_authz_id"

  create_table "account_group_self_group_assignments", :force => true do |t|
    t.integer  "account_group_id",   :null => false
    t.integer  "self_group_id",      :null => false
    t.boolean  "virtual_assignment"
    t.datetime "assigned_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "account_group_self_group_assignments", ["account_group_id", "self_group_id"], :name => "index_on_agsga_ag_sg"
  add_index "account_group_self_group_assignments", ["account_group_id"], :name => "index_account_group_self_group_assignments_on_account_group_id"
  add_index "account_group_self_group_assignments", ["self_group_id"], :name => "index_account_group_self_group_assignments_on_self_group_id"
  add_index "account_group_self_group_assignments", ["virtual_assignment"], :name => "index_account_group_self_group_assignments_on_virtual_assignment"

  create_table "account_groups", :force => true do |t|
    t.string   "name",        :null => false
    t.string   "description"
    t.integer  "slfgrp"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "account_groups", ["name"], :name => "index_account_groups_on_name"
  add_index "account_groups", ["slfgrp"], :name => "index_account_groups_on_slfgrp"

  create_table "accounts", :force => true do |t|
    t.string   "name"
    t.string   "login"
    t.string   "password_hash"
    t.string   "password_salt"
    t.string   "email_address"
    t.boolean  "admin",         :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "accounts", ["id"], :name => "index_accounts_on_id"
  add_index "accounts", ["name"], :name => "index_accounts_on_name"

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

  add_index "audits", ["auditable_id", "auditable_type"], :name => "auditable_index"
  add_index "audits", ["created_at"], :name => "index_audits_on_created_at"
  add_index "audits", ["user_id", "user_type"], :name => "user_index"

  create_table "comments", :force => true do |t|
    t.string   "title",            :limit => 50, :default => ""
    t.text     "comment"
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
  end

  add_index "database_instance_relationships", ["assigned_at"], :name => "index_database_instance_relationships_on_assigned_at"
  add_index "database_instance_relationships", ["from_id"], :name => "index_database_instance_relationships_on_from_id"
  add_index "database_instance_relationships", ["id"], :name => "index_database_instance_relationships_on_id"
  add_index "database_instance_relationships", ["name"], :name => "index_database_instance_relationships_on_name"
  add_index "database_instance_relationships", ["to_id"], :name => "index_database_instance_relationships_on_to_id"

  create_table "database_instances", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "database_instances", ["id"], :name => "index_database_instances_on_id"
  add_index "database_instances", ["name"], :name => "index_database_instances_on_name"

  create_table "datacenter_node_rack_assignments", :force => true do |t|
    t.integer  "datacenter_id"
    t.integer  "node_rack_id"
    t.datetime "assigned_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "datacenter_node_rack_assignments", ["assigned_at"], :name => "index_datacenter_rack_assignments_on_assigned_at"
  add_index "datacenter_node_rack_assignments", ["datacenter_id"], :name => "index_datacenter_rack_assignments_on_datacenter_id"
  add_index "datacenter_node_rack_assignments", ["id"], :name => "index_datacenter_rack_assignments_on_id"
  add_index "datacenter_node_rack_assignments", ["node_rack_id"], :name => "index_datacenter_rack_assignments_on_rack_id"

  create_table "datacenter_vip_assignments", :force => true do |t|
    t.integer  "datacenter_id", :null => false
    t.integer  "vip_id",        :null => false
    t.integer  "priority"
    t.datetime "assigned_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "datacenter_vip_assignments", ["assigned_at"], :name => "index_datacenter_vip_assignments_on_assigned_at"
  add_index "datacenter_vip_assignments", ["datacenter_id", "vip_id"], :name => "index_datacenter_vip_assignments_on_datacenter_id_and_vip_id"
  add_index "datacenter_vip_assignments", ["vip_id"], :name => "index_datacenter_vip_assignments_on_vip_id"

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
  end

  add_index "datacenters", ["id"], :name => "index_datacenters_on_id"
  add_index "datacenters", ["name"], :name => "index_datacenters_on_name"

  create_table "drives", :force => true do |t|
    t.string   "name",                               :null => false
    t.integer  "storage_controller_id"
    t.string   "logicalname"
    t.string   "vendor"
    t.string   "physid"
    t.string   "businfo"
    t.string   "handle"
    t.string   "serial"
    t.string   "description"
    t.string   "product"
    t.integer  "size",                  :limit => 8
    t.string   "dev"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

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
    t.string   "visualization_color",     :default => "red"
    t.string   "outlet_type"
    t.integer  "power_supply_count"
    t.string   "model"
    t.string   "processor_manufacturer"
    t.integer  "processor_socket_count"
    t.integer  "power_supply_slot_count"
    t.integer  "power_consumption"
  end

  add_index "hardware_profiles", ["id"], :name => "index_hardware_profiles_on_id"
  add_index "hardware_profiles", ["name"], :name => "index_hardware_profiles_on_name"

  create_table "ip_address_network_port_assignments", :force => true do |t|
    t.integer  "ip_address_id"
    t.integer  "network_port_id"
    t.string   "apps"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "assigned_at"
    t.datetime "nmap_first_seen_at"
    t.datetime "nmap_last_seen_at"
  end

  add_index "ip_address_network_port_assignments", ["apps"], :name => "index_ip_address_network_port_assignments_on_apps"
  add_index "ip_address_network_port_assignments", ["created_at"], :name => "index_ip_address_network_port_assignments_on_created_at"
  add_index "ip_address_network_port_assignments", ["ip_address_id"], :name => "index_ip_address_network_port_assignments_on_ip_address_id"
  add_index "ip_address_network_port_assignments", ["network_port_id"], :name => "index_ip_address_network_port_assignments_on_network_port_id"
  add_index "ip_address_network_port_assignments", ["nmap_first_seen_at"], :name => "index_ip_address_network_port_assignments_on_nmap_first_seen_at"
  add_index "ip_address_network_port_assignments", ["nmap_last_seen_at"], :name => "index_ip_address_network_port_assignments_on_nmap_last_seen_at"
  add_index "ip_address_network_port_assignments", ["updated_at"], :name => "index_ip_address_network_port_assignments_on_updated_at"

  create_table "ip_addresses", :force => true do |t|
    t.integer  "network_interface_id"
    t.string   "address",              :null => false
    t.string   "address_type",         :null => false
    t.string   "netmask"
    t.string   "broadcast"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "nmap_last_scanned_at"
  end

  add_index "ip_addresses", ["address"], :name => "index_ip_addresses_on_address"
  add_index "ip_addresses", ["network_interface_id"], :name => "index_ip_addresses_on_network_interface_id"

  create_table "lb_profiles", :force => true do |t|
    t.string   "protocol"
    t.string   "port"
    t.string   "lbmethod"
    t.string   "healthcheck"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "lb_pool_id"
  end

  add_index "lb_profiles", ["created_at"], :name => "index_lb_profiles_on_created_at"
  add_index "lb_profiles", ["healthcheck"], :name => "index_lb_profiles_on_healthcheck"
  add_index "lb_profiles", ["id"], :name => "index_lb_profiles_on_id"
  add_index "lb_profiles", ["lbmethod"], :name => "index_lb_profiles_on_lbmethod"
  add_index "lb_profiles", ["port"], :name => "index_lb_profiles_on_port"
  add_index "lb_profiles", ["updated_at"], :name => "index_lb_profiles_on_updated_at"

  create_table "name_aliases", :force => true do |t|
    t.string   "name"
    t.integer  "source_id"
    t.string   "source_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "name_aliases", ["created_at"], :name => "index_name_aliases_on_created_at"
  add_index "name_aliases", ["id"], :name => "index_name_aliases_on_id"
  add_index "name_aliases", ["name"], :name => "index_name_aliases_on_name"
  add_index "name_aliases", ["source_id", "name"], :name => "source_id_name"
  add_index "name_aliases", ["source_id"], :name => "index_name_aliases_on_source_id"
  add_index "name_aliases", ["source_type"], :name => "index_name_aliases_on_source_type"
  add_index "name_aliases", ["updated_at"], :name => "index_name_aliases_on_updated_at"

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
  end

  add_index "network_interfaces", ["name"], :name => "index_network_interfaces_on_name"
  add_index "network_interfaces", ["node_id"], :name => "index_network_interfaces_on_node_id"

  create_table "network_ports", :force => true do |t|
    t.string   "protocol",   :null => false
    t.integer  "number",     :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "network_ports", ["created_at"], :name => "index_network_ports_on_created_at"
  add_index "network_ports", ["number"], :name => "index_network_ports_on_number"
  add_index "network_ports", ["protocol"], :name => "index_network_ports_on_protocol"
  add_index "network_ports", ["updated_at"], :name => "index_network_ports_on_updated_at"

  create_table "ng_app_keywords", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "ng_app_keywords", ["id"], :name => "index_ng_app_keywords_on_id"
  add_index "ng_app_keywords", ["name"], :name => "index_ng_app_keywords_on_name"

  create_table "node_database_instance_assignments", :force => true do |t|
    t.integer  "node_id"
    t.integer  "database_instance_id"
    t.datetime "assigned_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "node_database_instance_assignments", ["assigned_at"], :name => "index_node_database_instance_assignments_on_assigned_at"
  add_index "node_database_instance_assignments", ["database_instance_id"], :name => "index_node_database_instance_assignments_on_database_instance_id"
  add_index "node_database_instance_assignments", ["id"], :name => "index_node_database_instance_assignments_on_id"
  add_index "node_database_instance_assignments", ["node_id"], :name => "index_node_database_instance_assignments_on_node_id"

  create_table "node_group_node_assignments", :force => true do |t|
    t.integer  "node_id",            :null => false
    t.integer  "node_group_id",      :null => false
    t.datetime "assigned_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "virtual_assignment"
  end

  add_index "node_group_node_assignments", ["assigned_at"], :name => "index_node_group_node_assignments_on_assigned_at"
  add_index "node_group_node_assignments", ["node_group_id"], :name => "index_node_group_node_assignments_on_node_group_id"
  add_index "node_group_node_assignments", ["node_id", "node_group_id"], :name => "index_node_group_node_assignments_on_node_id_and_node_group_id"
  add_index "node_group_node_assignments", ["virtual_assignment"], :name => "index_node_group_node_assignments_on_virtual_assignment"

  create_table "node_group_node_group_assignments", :force => true do |t|
    t.integer  "parent_id",   :null => false
    t.integer  "child_id",    :null => false
    t.datetime "assigned_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "node_group_node_group_assignments", ["assigned_at"], :name => "index_node_group_node_group_assignments_on_assigned_at"
  add_index "node_group_node_group_assignments", ["child_id"], :name => "index_node_group_node_group_assignments_on_child_id"
  add_index "node_group_node_group_assignments", ["parent_id", "child_id"], :name => "parent_child_index"

  create_table "node_group_vip_assignments", :force => true do |t|
    t.integer  "vip_id",             :null => false
    t.integer  "node_group_id",      :null => false
    t.boolean  "virtual_assignment"
    t.datetime "assigned_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  add_index "node_group_vip_assignments", ["assigned_at"], :name => "index_node_group_vip_assignments_on_assigned_at"
  add_index "node_group_vip_assignments", ["deleted_at"], :name => "index_node_group_vip_assignments_on_deleted_at"
  add_index "node_group_vip_assignments", ["node_group_id"], :name => "index_node_group_vip_assignments_on_node_group_id"
  add_index "node_group_vip_assignments", ["vip_id", "node_group_id"], :name => "index_node_group_vip_assignments_on_vip_id_and_node_group_id"

  create_table "node_groups", :force => true do |t|
    t.string   "name",        :null => false
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "owner"
  end

  add_index "node_groups", ["name"], :name => "index_node_groups_on_name", :unique => true
  add_index "node_groups", ["owner"], :name => "index_node_groups_on_owner"

  create_table "node_rack_node_assignments", :force => true do |t|
    t.integer  "node_rack_id"
    t.integer  "node_id"
    t.integer  "position"
    t.datetime "assigned_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "node_rack_node_assignments", ["assigned_at"], :name => "index_rack_node_assignments_on_assigned_at"
  add_index "node_rack_node_assignments", ["id"], :name => "index_rack_node_assignments_on_id"
  add_index "node_rack_node_assignments", ["node_id"], :name => "index_rack_node_assignments_on_node_id"
  add_index "node_rack_node_assignments", ["node_rack_id"], :name => "index_rack_node_assignments_on_rack_id"

  create_table "node_racks", :force => true do |t|
    t.string   "name"
    t.text     "location"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.integer  "u_height",    :default => 42
  end

  add_index "node_racks", ["deleted_at"], :name => "index_racks_on_deleted_at"
  add_index "node_racks", ["id"], :name => "index_racks_on_id"
  add_index "node_racks", ["name"], :name => "index_racks_on_name"

  create_table "nodes", :force => true do |t|
    t.string   "name"
    t.string   "serial_number"
    t.datetime "created_at"
    t.datetime "updated_at"
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
    t.string   "timezone"
    t.datetime "expiration"
    t.text     "contact"
    t.string   "virtualarch"
    t.integer  "vmimg_size"
    t.integer  "vmspace_used"
    t.integer  "used_space"
    t.integer  "avail_space"
    t.integer  "os_virtual_processor_count"
    t.string   "config_mgmt_tag"
  end

  add_index "nodes", ["avail_space"], :name => "index_nodes_on_avail_space"
  add_index "nodes", ["config_mgmt_tag"], :name => "index_nodes_on_config_mgmt_tag"
  add_index "nodes", ["expiration"], :name => "index_nodes_on_expiration"
  add_index "nodes", ["hardware_profile_id"], :name => "index_nodes_on_hardware_profile_id"
  add_index "nodes", ["id"], :name => "index_nodes_on_id"
  add_index "nodes", ["name"], :name => "index_nodes_on_name"
  add_index "nodes", ["os_virtual_processor_count"], :name => "index_nodes_on_os_virtual_processor_count"
  add_index "nodes", ["serial_number"], :name => "index_nodes_on_serial_number"
  add_index "nodes", ["status_id"], :name => "index_nodes_on_status_id"
  add_index "nodes", ["timezone"], :name => "index_nodes_on_timezone"
  add_index "nodes", ["uniqueid"], :name => "index_nodes_on_uniqueid"
  add_index "nodes", ["used_space"], :name => "index_nodes_on_used_space"
  add_index "nodes", ["virtualarch"], :name => "index_nodes_on_virtualarch"
  add_index "nodes", ["vmimg_size"], :name => "index_nodes_on_vmimg_size"
  add_index "nodes", ["vmspace_used"], :name => "index_nodes_on_vmspace_used"

  create_table "operating_systems", :force => true do |t|
    t.string   "name"
    t.string   "vendor"
    t.string   "variant"
    t.string   "version_number"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "architecture"
    t.text     "description"
  end

  add_index "operating_systems", ["id"], :name => "index_operating_systems_on_id"
  add_index "operating_systems", ["name"], :name => "index_operating_systems_on_name"

  create_table "outlets", :force => true do |t|
    t.string   "name"
    t.integer  "producer_id"
    t.integer  "consumer_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "consumer_type", :default => "Node"
  end

  add_index "outlets", ["consumer_id"], :name => "index_outlets_on_consumer_id"
  add_index "outlets", ["consumer_type"], :name => "index_outlets_on_consumer_type"
  add_index "outlets", ["id"], :name => "index_outlets_on_id"
  add_index "outlets", ["name"], :name => "index_outlets_on_name"
  add_index "outlets", ["producer_id"], :name => "index_outlets_on_producer_id"

  create_table "roles", :force => true do |t|
    t.string   "name",              :limit => 40
    t.string   "authorizable_type", :limit => 40
    t.integer  "authorizable_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "roles", ["authorizable_id"], :name => "index_roles_on_authorizable_id"
  add_index "roles", ["name"], :name => "index_roles_on_name"

  create_table "roles_users", :force => true do |t|
    t.integer  "account_group_id"
    t.integer  "role_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "attrs"
  end

  add_index "roles_users", ["account_group_id"], :name => "index_roles_users_on_account_group_id"

  create_table "service_profiles", :force => true do |t|
    t.integer  "service_id"
    t.string   "dev_url"
    t.string   "qa_url"
    t.string   "stg_url"
    t.string   "prod_url"
    t.string   "repo_url"
    t.string   "contact"
    t.string   "codelang"
    t.boolean  "external"
    t.boolean  "pciscope"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "service_profiles", ["codelang"], :name => "index_service_profiles_on_codelang"
  add_index "service_profiles", ["contact"], :name => "index_service_profiles_on_contact"
  add_index "service_profiles", ["created_at"], :name => "index_service_profiles_on_created_at"
  add_index "service_profiles", ["dev_url"], :name => "index_service_profiles_on_dev_url"
  add_index "service_profiles", ["external"], :name => "index_service_profiles_on_external"
  add_index "service_profiles", ["pciscope"], :name => "index_service_profiles_on_pciscope"
  add_index "service_profiles", ["prod_url"], :name => "index_service_profiles_on_prod_url"
  add_index "service_profiles", ["qa_url"], :name => "index_service_profiles_on_qa_url"
  add_index "service_profiles", ["repo_url"], :name => "index_service_profiles_on_repo_url"
  add_index "service_profiles", ["service_id"], :name => "index_service_profiles_on_service_id"
  add_index "service_profiles", ["stg_url"], :name => "index_service_profiles_on_stg_url"
  add_index "service_profiles", ["updated_at"], :name => "index_service_profiles_on_updated_at"

  create_table "service_service_assignments", :force => true do |t|
    t.integer  "parent_id",   :null => false
    t.integer  "child_id",    :null => false
    t.datetime "assigned_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "service_service_assignments", ["assigned_at"], :name => "assigned_at_index"
  add_index "service_service_assignments", ["child_id"], :name => "child_index"
  add_index "service_service_assignments", ["parent_id", "child_id"], :name => "parent_child_index"

  create_table "sessions", :force => true do |t|
    t.string   "session_id"
    t.text     "data"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "statuses", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "statuses", ["id"], :name => "index_statuses_on_id"
  add_index "statuses", ["name"], :name => "index_statuses_on_name"

  create_table "storage_controllers", :force => true do |t|
    t.string   "name",            :null => false
    t.string   "controller_type"
    t.boolean  "physical"
    t.string   "businfo"
    t.string   "slot"
    t.string   "firmware"
    t.integer  "cache_size"
    t.integer  "batteries"
    t.integer  "node_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "product"
    t.string   "description"
    t.string   "physid"
    t.string   "vendor"
    t.string   "handle"
    t.string   "logicalname"
  end

  add_index "storage_controllers", ["batteries"], :name => "index_storage_controllers_on_batteries"
  add_index "storage_controllers", ["businfo"], :name => "index_storage_controllers_on_businfo"
  add_index "storage_controllers", ["cache_size"], :name => "index_storage_controllers_on_cache_size"
  add_index "storage_controllers", ["controller_type"], :name => "index_storage_controllers_on_controller_type"
  add_index "storage_controllers", ["created_at"], :name => "index_storage_controllers_on_created_at"
  add_index "storage_controllers", ["description"], :name => "index_storage_controllers_on_description"
  add_index "storage_controllers", ["firmware"], :name => "index_storage_controllers_on_firmware"
  add_index "storage_controllers", ["handle"], :name => "index_storage_controllers_on_handle"
  add_index "storage_controllers", ["logicalname"], :name => "index_storage_controllers_on_logicalname"
  add_index "storage_controllers", ["name"], :name => "index_storage_controllers_on_name"
  add_index "storage_controllers", ["node_id"], :name => "index_storage_controllers_on_node_id"
  add_index "storage_controllers", ["physical"], :name => "index_storage_controllers_on_physical"
  add_index "storage_controllers", ["physid"], :name => "index_storage_controllers_on_physid"
  add_index "storage_controllers", ["product"], :name => "index_storage_controllers_on_product"
  add_index "storage_controllers", ["slot"], :name => "index_storage_controllers_on_slot"
  add_index "storage_controllers", ["updated_at"], :name => "index_storage_controllers_on_updated_at"
  add_index "storage_controllers", ["vendor"], :name => "index_storage_controllers_on_vendor"

  create_table "subnets", :force => true do |t|
    t.string   "network",       :null => false
    t.string   "netmask",       :null => false
    t.string   "gateway",       :null => false
    t.string   "broadcast",     :null => false
    t.string   "resolvers"
    t.integer  "node_group_id"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "subnets", ["network"], :name => "index_subnets_on_network", :unique => true
  add_index "subnets", ["node_group_id"], :name => "index_subnets_on_node_group_id"

  create_table "taggings", :force => true do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.string   "taggable_type"
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id"], :name => "index_taggings_on_tag_id"
  add_index "taggings", ["taggable_id", "taggable_type"], :name => "index_taggings_on_taggable_id_and_taggable_type"

  create_table "tags", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tool_tips", :force => true do |t|
    t.string   "model"
    t.string   "attr"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "tool_tips", ["attr"], :name => "index_tool_tips_on_attr"
  add_index "tool_tips", ["created_at"], :name => "index_tool_tips_on_created_at"
  add_index "tool_tips", ["model"], :name => "index_tool_tips_on_model"
  add_index "tool_tips", ["updated_at"], :name => "index_tool_tips_on_updated_at"

  create_table "utilization_metric_names", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "utilization_metric_names", ["created_at"], :name => "index_utilization_metric_names_on_created_at"
  add_index "utilization_metric_names", ["id"], :name => "index_utilization_metric_names_on_id"
  add_index "utilization_metric_names", ["name"], :name => "index_utilization_metric_names_on_name"
  add_index "utilization_metric_names", ["updated_at"], :name => "index_utilization_metric_names_on_updated_at"

  create_table "utilization_metrics", :force => true do |t|
    t.integer  "utilization_metric_name_id"
    t.integer  "node_id"
    t.string   "value"
    t.datetime "assigned_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "utilization_metrics", ["assigned_at"], :name => "index_utilization_metrics_on_assigned_at"
  add_index "utilization_metrics", ["created_at"], :name => "index_utilization_metrics_on_created_at"
  add_index "utilization_metrics", ["id"], :name => "index_utilization_metrics_on_id"
  add_index "utilization_metrics", ["node_id"], :name => "index_utilization_metrics_on_node_id"
  add_index "utilization_metrics", ["updated_at"], :name => "index_utilization_metrics_on_updated_at"
  add_index "utilization_metrics", ["utilization_metric_name_id"], :name => "index_utilization_metrics_on_utilization_metric_name_id"
  add_index "utilization_metrics", ["value"], :name => "index_utilization_metrics_on_value"

  create_table "utilization_metrics_by_node_groups", :force => true do |t|
    t.integer  "utilization_metric_name_id"
    t.integer  "node_group_id"
    t.string   "value"
    t.datetime "assigned_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "node_count"
  end

  add_index "utilization_metrics_by_node_groups", ["assigned_at"], :name => "index_utilization_metrics_by_node_groups_on_assigned_at"
  add_index "utilization_metrics_by_node_groups", ["created_at"], :name => "index_utilization_metrics_by_node_groups_on_created_at"
  add_index "utilization_metrics_by_node_groups", ["id"], :name => "index_utilization_metrics_by_node_groups_on_id"
  add_index "utilization_metrics_by_node_groups", ["node_group_id"], :name => "index_utilization_metrics_by_node_groups_on_node_group_id"
  add_index "utilization_metrics_by_node_groups", ["updated_at"], :name => "index_utilization_metrics_by_node_groups_on_updated_at"
  add_index "utilization_metrics_by_node_groups", ["utilization_metric_name_id"], :name => "index_utilization_metrics_by_node_groups_on_utilz_metric_name_id"
  add_index "utilization_metrics_by_node_groups", ["value"], :name => "index_utilization_metrics_by_node_groups_on_value"

  create_table "utilization_metrics_globals", :force => true do |t|
    t.integer  "utilization_metric_name_id"
    t.string   "value"
    t.datetime "assigned_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "node_count"
  end

  add_index "utilization_metrics_globals", ["assigned_at"], :name => "index_utilization_metrics_globals_on_assigned_at"
  add_index "utilization_metrics_globals", ["created_at"], :name => "index_utilization_metrics_globals_on_created_at"
  add_index "utilization_metrics_globals", ["id"], :name => "index_utilization_metrics_globals_on_id"
  add_index "utilization_metrics_globals", ["updated_at"], :name => "index_utilization_metrics_globals_on_updated_at"
  add_index "utilization_metrics_globals", ["utilization_metric_name_id"], :name => "index_utilization_metrics_globals_on_utilization_metric_name_id"
  add_index "utilization_metrics_globals", ["value"], :name => "index_utilization_metrics_globals_on_value"

  create_table "vip_lb_pool_assignments", :force => true do |t|
    t.integer  "vip_id",      :null => false
    t.integer  "lb_pool_id",  :null => false
    t.datetime "assigned_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "vip_lb_pool_assignments", ["assigned_at"], :name => "assigned_at_index"
  add_index "vip_lb_pool_assignments", ["lb_pool_id"], :name => "lb_pool_index"
  add_index "vip_lb_pool_assignments", ["vip_id", "lb_pool_id"], :name => "vip_lb_pool_index"

  create_table "vips", :force => true do |t|
    t.string   "name",             :null => false
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "load_balancer_id"
    t.string   "ip_address"
    t.string   "protocol"
    t.integer  "port"
    t.integer  "ip_address_id"
  end

  add_index "vips", ["ip_address"], :name => "index_vips_on_ip_address"
  add_index "vips", ["load_balancer_id"], :name => "index_vips_on_load_balancer_id"
  add_index "vips", ["name"], :name => "index_vips_on_name", :unique => true
  add_index "vips", ["port"], :name => "index_vips_on_port"
  add_index "vips", ["protocol"], :name => "index_vips_on_protocol"

  create_table "virtual_assignments", :force => true do |t|
    t.integer  "parent_id",   :null => false
    t.integer  "child_id",    :null => false
    t.datetime "assigned_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "virtual_assignments", ["assigned_at"], :name => "assigned_at_index"
  add_index "virtual_assignments", ["child_id"], :name => "child_index"
  add_index "virtual_assignments", ["parent_id", "child_id"], :name => "parent_child_index"

  create_table "volume_drive_assignments", :force => true do |t|
    t.integer  "volume_id",   :null => false
    t.integer  "drive_id",    :null => false
    t.datetime "assigned_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "volume_drive_assignments", ["assigned_at"], :name => "index_volume_drive_assignments_on_assigned_at"
  add_index "volume_drive_assignments", ["drive_id"], :name => "index_volume_drive_assignments_on_drive_id"
  add_index "volume_drive_assignments", ["volume_id"], :name => "index_volume_drive_assignments_on_volume_id"

  create_table "volume_node_assignments", :force => true do |t|
    t.integer  "volume_id"
    t.integer  "node_id"
    t.string   "mount"
    t.string   "configf"
    t.datetime "assigned_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "volume_node_assignments", ["assigned_at"], :name => "index_volume_node_assignments_on_assigned_at"
  add_index "volume_node_assignments", ["id"], :name => "index_volume_node_assignments_on_id"
  add_index "volume_node_assignments", ["mount"], :name => "index_volume_node_assignments_on_mount"
  add_index "volume_node_assignments", ["node_id"], :name => "index_volume_node_assignments_on_node_id"
  add_index "volume_node_assignments", ["volume_id"], :name => "index_volume_node_assignments_on_volume_id"

  create_table "volumes", :force => true do |t|
    t.string   "name"
    t.string   "volume_type"
    t.string   "configf"
    t.integer  "volume_server_id"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "capacity",         :limit => 8
    t.integer  "size",             :limit => 8
    t.string   "vendor"
    t.string   "businfo"
    t.string   "serial"
    t.string   "physid"
    t.string   "dev"
    t.string   "logicalname"
  end

  add_index "volumes", ["businfo"], :name => "index_volumes_on_businfo"
  add_index "volumes", ["capacity"], :name => "index_volumes_on_capacity"
  add_index "volumes", ["configf"], :name => "index_volumes_on_configf"
  add_index "volumes", ["dev"], :name => "index_volumes_on_dev"
  add_index "volumes", ["id"], :name => "index_volumes_on_id"
  add_index "volumes", ["logicalname"], :name => "index_volumes_on_logicalname"
  add_index "volumes", ["name"], :name => "index_volumes_on_name"
  add_index "volumes", ["physid"], :name => "index_volumes_on_physid"
  add_index "volumes", ["serial"], :name => "index_volumes_on_serial"
  add_index "volumes", ["size"], :name => "index_volumes_on_size"
  add_index "volumes", ["vendor"], :name => "index_volumes_on_vendor"
  add_index "volumes", ["volume_server_id"], :name => "index_volumes_on_volume_server_id"
  add_index "volumes", ["volume_type"], :name => "index_volumes_on_volume_type"

end
