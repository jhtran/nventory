class Node < ActiveRecord::Base
  named_scope :def_scope
  
  acts_as_authorizable
  acts_as_reportable
  acts_as_commentable
  acts_as_audited :except => [:used_space, :avail_space, :vmspace_used]

  has_many :hosted_vips, :foreign_key => "load_balancer_id", :class_name => "Vip"
  has_one :node_rack_node_assignment, :dependent => :destroy
  has_one :node_rack, :through => :node_rack_node_assignment

  has_many :lb_pool_node_assignments, :dependent => :destroy
  has_many :lb_pools, :through => :lb_pool_node_assignments

  has_many :volumes_served, :dependent => :destroy, :foreign_key => 'volume_server_id', :class_name => 'Volume'
  has_many :volume_node_assignments, :dependent => :destroy
  has_many :volumes_mounted, :through => :volume_node_assignments, :source => :volume
  
  belongs_to :hardware_profile
  belongs_to :operating_system
  belongs_to :preferred_operating_system,
             :class_name => 'OperatingSystem',
             :foreign_key => 'preferred_operating_system_id'
  belongs_to :status
  
  has_many :node_group_node_assignments, :dependent => :destroy
  has_many :node_groups, :through => :node_group_node_assignments
  accepts_nested_attributes_for :node_groups, :allow_destroy => true
  # Services is an alias of node_groups
  has_many :services, :source => :service, :through => :node_group_node_assignments
  
  has_many :node_database_instance_assignments
  has_many :database_instances, :through => :node_database_instance_assignments
  
  has_many :produced_outlets, :class_name => "Outlet", :foreign_key => "producer_id", :order => "name", :dependent => :destroy
  accepts_nested_attributes_for :produced_outlets, :allow_destroy => true
  has_many :name_aliases, :foreign_key => "source_id", :order => "name", :dependent => :destroy

  has_many :network_interfaces, :dependent => :destroy
  has_many :ip_addresses, :through => :network_interfaces
  has_many :consumed_outlets, :class_name => "Outlet", :as => :consumer, :dependent => :destroy
  has_many :storage_controllers, :dependent => :destroy
  has_many :drives, :through => :storage_controllers
  
  has_many :utilization_metrics, :dependent => :destroy

  # Virtual Assignments
  has_many :virtual_assignments_as_host, 
           :foreign_key => 'parent_id',
           :class_name => 'VirtualAssignment',
           :dependent => :destroy
  has_one  :virtual_assignment_as_guest, 
           :foreign_key => 'child_id',
           :class_name => 'VirtualAssignment',
           :dependent => :destroy
  has_one  :virtual_host, :through => :virtual_assignment_as_guest
  has_many :virtual_guests,  :through => :virtual_assignments_as_host

  validates_presence_of :name, :hardware_profile_id, :status_id

  unless MyConfig.allow_duplicate_hostname 
    validates_uniqueness_of :name
  end
  validates_uniqueness_of :uniqueid, :allow_nil => true, :allow_blank => true
  
  validates_numericality_of :processor_socket_count, :only_integer => true, :greater_than_or_equal_to => 0, :allow_nil => true
  validates_numericality_of :processor_count,        :only_integer => true, :greater_than_or_equal_to => 0, :allow_nil => true
  validates_numericality_of :processor_core_count,   :only_integer => true, :greater_than_or_equal_to => 0, :allow_nil => true
  validates_numericality_of :os_processor_count,     :only_integer => true, :greater_than_or_equal_to => 0, :allow_nil => true
  validates_numericality_of :power_supply_count,     :only_integer => true, :greater_than_or_equal_to => 0, :allow_nil => true
  #validates_format_of :virtualarch, :with => /^(xen|vmware)$/i, :if => :virtualarch

  CONSOLE_TYPES = ['','Serial','HP iLO','Dell DRAC','Sun RSC','Sun ALOM']
  def self.allowed_console_types
    return CONSOLE_TYPES
  end

  # If a console type has been specified make sure it is one of the
  # allowed types
  validates_inclusion_of :console_type,
                         :in => CONSOLE_TYPES,
                         :allow_nil => true,
                         :message => "not one of the allowed console " +
                            "types: #{CONSOLE_TYPES.join(',')}"

  def validate
    validates_contact
    validates_virtualarch
  end

  def validates_virtualarch
    if (virtualarch.blank? || virtualarch.nil?)
      return true
    else
      unless virtualarch.match(/^(xen|vmware)$/i)
        errors.add(:virtualarch, "#{virtualarch} - invalid.  Can only be \"xen\" or \"vmware\"\n")
        return false
      end
    end
  end

  def validates_contact
    if (contact.blank? || contact.nil?)
      return true
    elsif SSO_AUTH_SERVER
      flag = []
      users = contact.split(',')
      users.each do |user|
        user.strip!
        uri = URI.parse("https://#{SSO_AUTH_SERVER}/users.xml?login=#{user}")
        http = Net::HTTP::Proxy(SSO_PROXY_SERVER,8080).new(uri.host,uri.port)
        http.use_ssl = true
        sso_xmldata = http.get(uri.request_uri).body
        sso_xmldoc = Hpricot::XML(sso_xmldata)
        if (sso_xmldoc/:kind).first
          kind = (sso_xmldoc/:kind).first.innerHTML
          unless kind == "employee"|| kind == "contractor"
            flag << user
          end
        else
          flag << user
        end # if (sso_xmldoc/:kind).first
      end
    end
    if (flag.nil? || flag.empty?)
      return true 
    else
      errors.add(:contact, "Unknown user #{flag.join(' ')} or invalid format specified in contact field.\n(Example: jsmith,mjones,kgates)\n")
      return false
    end
  end

  def self.default_search_attribute
    'name'
  end

  def self.default_includes
    # The default display index_row columns
    return [:operating_system, :hardware_profile, :node_groups, :status, :name_aliases]
  end

  def self.custom_search_assocs
    # used in search view for each model, assumption is that search_for_association method in search.rb model will auto find the nested include path 
    # provide a hash pair { :name_of_assoc => :assoc's_search_attr }
    {:tag => 'name'}
  end

  def self.preferred_includes
    incls = {}
    incls[:ip_addresses] = { :assoc => NetworkInterface.reflect_on_association(:ip_addresses),
                             :include => {:network_interfaces=>{:ip_addresses=>{}}}}
    incls[:node_groups] = { :assoc => NodeGroupNodeAssignment.reflect_on_association(:node_group),
                             :include => {:node_group_node_assignments=>{:node_group=>{}}}}
    incls[:node_group] = { :assoc => NodeGroupNodeAssignment.reflect_on_association(:node_group),
                             :include => {:node_group_node_assignments=>{:node_group=>{}}}}
    incls[:tag] = { :assoc => Tagging.reflect_on_association(:tag),
                             :include => {:node_group_node_assignments=>{:node_group=>{:taggings=>{:tag=>{}}}}}}
    incls[:tags] = { :assoc => Tagging.reflect_on_association(:tag),
                             :include => {:node_group_node_assignments=>{:node_group=>{:taggings=>{:tag=>{}}}}}}
    return incls
  end

  def virtual_host?
    if (!virtual_guests.nil? && !virtual_guests.empty?)
      return true
    else
      return false
    end
  end

  def virtual_guest?
    if (!virtual_host.nil?)
      return true
    else
      return false
    end
  end

 
  def all_parent_groups
    list = []
    node_groups.each do |ng|
      list << ng
      ng.all_parent_groups.each{|a| list << a}
    end
    return list
  end

  def real_node_group_node_assignments
    node_group_node_assignments.reject { |ngna| ngna.virtual_assignment? }
  end
  def real_node_groups
    real_node_group_node_assignments.collect { |ngna| ngna.node_group }
  end
  def recursive_real_node_groups
    results = []
    real_node_group_node_assignments.each do |rngna|
      results << rngna.node_group
      rngna.node_group.child_groups.each do |rngcg|
        results << rngcg
      end
    end
    results
  end
  def virtual_node_group_node_assignments
    node_group_node_assignments.select { |ngna| ngna.virtual_assignment? }
  end
  def virtual_node_groups
    virtual_node_group_node_assignments.collect { |ngna| ngna.node_group }
  end

  
  def consumed_network_outlets
    return self.network_interfaces.collect{|nic| nic.switch_port}.compact
  end
  
  def consumed_power_outlets
    power_outlets = []
    self.consumed_outlets.each { |outlet| power_outlets << outlet if outlet.producer.hardware_profile.outlet_type == "Power" }
    return power_outlets
  end
  
  def consumed_console_outlets
    console_outlets = []
    self.consumed_outlets.each { |outlet| console_outlets << outlet if outlet.producer.hardware_profile.outlet_type == "Console" }
    return console_outlets
  end
  
  def visualization_summary
    # This is the text we'll show in a node box when we visualize a rack
    delimiter = ' | '
    # FIXME: This should be replaced with something that doesn't use
    # functions.  Seems like if we want to treat PDUs, switches and console
    # servers specially we should flag their hardware profiles.
    #function_names = []
    #self.functions.each { |f| function_names << f.name }
    #if function_names.include?("PDU") or function_names.include?("Network Switch")
      # PDUs and switches should display: name, IP, hwprofile, # of total outlets, free outlets
      #active_outlet_count = 0
      #self.outlets.each { |o|
      #  active_outlet_count = active_outlet_count + 1 unless o.consumer.nil?
      #}
      #return self.name + delimiter + self.hardware_profile.name + delimiter + active_outlet_count.to_s + '/' + self.hardware_profile.outlet_count.to_s
    #else
      return self.name + delimiter + self.hardware_profile.name
    #end
  end
  
  def update_outlets(outlet_names=nil)
    if !self.hardware_profile.outlet_count.nil?
      # Make sure we have the correct number of outlets realized in the database.
      how_many_needed = nil
      if self.hardware_profile.outlet_count > 0
        how_many_needed = self.hardware_profile.outlet_count
      elsif outlet_names # self.hardware_profile.outlet_count == 0
        # If the hardware profile outlet count is 0 we dynamically allocate
        # outlets based on how many outlet names the user supplied.
        # Many switches are chassis-based with multiple cards or slots, so
        # they don't have a fixed number of outlets.
        how_many_needed = outlet_names.length
      end
      if how_many_needed && self.produced_outlets.length != how_many_needed
        if self.produced_outlets.length < how_many_needed
          # We need to add outlets
          how_many_to_add = how_many_needed - self.produced_outlets.length
          how_many_to_add.times { self.add_new_outlet }
        else
          # We need to remove outlets
          how_many_to_remove = self.produced_outlets.length - how_many_needed
          # If the user supplied outlet names try to remove outlets with
          # names that don't match
          if outlet_names
            self.produced_outlets.each do |outlet|
              if !outlet_names.include?(outlet.name)
                outlet.destroy
                how_many_to_remove -= 1
                break if how_many_to_remove == 0
              end
            end
          end
          how_many_to_remove.times { self.remove_bottom_outlet }
        end
      end

      # Set outlet names
      if outlet_names
        # It would be a nice improvement if the names were applied as we
        # created outlets, rather than creating the outlet with a generic
        # name above and then renaming it here.

        # Try to leave as many outlet names untouched as possible, by
        # picking out for renaming only the outlets with names that don't
        # match any of the incoming names.  That should limit any scrambling
        # of outlet assignments to consumers.
        available_outlet_names = {}
        outlet_names.each { |name| available_outlet_names[name] = true }
        outlet_needs_renaming = []
        self.produced_outlets.each do |outlet|
          if available_outlet_names.has_key?(outlet.name)
            available_outlet_names.delete(outlet.name)
          else
            outlet_needs_renaming << outlet
          end
        end

        available_outlet_names.keys.sort.each do |oname|
          next if outlet_needs_renaming.empty?
          outlet = outlet_needs_renaming.last
          outlet.update_attributes({:name => oname}) unless outlet.frozen?
          outlet_needs_renaming.pop
        end
      end
    end
  end
  
  def add_new_outlet(name=nil)
    # Find out how many outlets we currently have
    count = self.produced_outlets(true).length + 1
    o = Outlet.new
    if !name
      o.name = count.to_s
    end
    o.producer = self
    o.save
  end
  
  def remove_bottom_outlet
    self.produced_outlets.last.destroy
  end
  
  # If NICs have been configured for this node then check the count of
  # physical NICs.  Otherwise fall back to the number of NICs defined in
  # the node's hardware model.
  def number_of_physical_nics
    number_of_physical_nics =
      self.network_interfaces.find_all_by_physical(true).length
    if number_of_physical_nics > 0
      return number_of_physical_nics
    elsif self.hardware_profile.nics
      return self.hardware_profile.nics
    else
      return 0
    end
  end

  def number_of_power_supplies
    if self.power_supply_count
      return self.power_supply_count
    elsif self.hardware_profile.power_supply_count
      return self.hardware_profile.power_supply_count
    else
      return 0
    end
  end

  def ips
    self.ip_addresses.collect{|ip| ip.address}.find_all{ |ip| ip =~ /\b(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b/ && ip !~ /127\.0\.0\.1/}
  end

  def after_save 
    unless self.hardware_profile.outlet_type.nil? || self.hardware_profile.outlet_type.empty?
      RAILS_DEFAULT_LOGGER.info "*** Updating outlets"
      update_outlets 
    end
  end

  def before_destroy
    raise "A node can not be destroyed that has database instances assigned to it." if !self.node_database_instance_assignments.nil? && self.node_database_instance_assignments.count > 0
  end

  def services?
    # need to be revisited - what's it used for?  diff than :services habtm
    self.services.each do |ng|
      return true unless (ng.parent_services.empty? && ng.child_services.empty?)
    end
    return false
  end

  def reset_node_groups
    self.real_node_group_node_assignments.each { |rngna| rngna.destroy }
  end

  def names
    self.name_aliases.collect {|na| na.name}.push(self.name).sort
  end

  def consumed_blade
    return nil if hardware_profile.outlet_type && hardware_profile.outlet_type == 'Blade'
    result = self.consumed_outlets.find(:first,:include => {:producer => {:hardware_profile =>{}} } , :conditions => "hardware_profiles.outlet_type = 'Blade'")
  end
  
end
