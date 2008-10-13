class Node < ActiveRecord::Base
  
  acts_as_paranoid
  acts_as_commentable
  
  has_one :rack_node_assignment, :dependent => :destroy
  has_one :rack, :through => :rack_node_assignment
  
  belongs_to :hardware_profile
  belongs_to :operating_system
  belongs_to :preferred_operating_system,
             :class_name => 'OperatingSystem',
             :foreign_key => 'preferred_operating_system_id'
  belongs_to :status
  
  has_many :node_group_node_assignments, :dependent => :destroy
  has_many :node_groups, :through => :node_group_node_assignments
  
  has_many :node_database_instance_assignments
  has_many :database_instances, :through => :node_database_instance_assignments
  
  has_many :produced_outlets, :class_name => "Outlet", :foreign_key => "producer_id", :order => "name", :dependent => :destroy
  has_many :consumed_outlets, :class_name => "Outlet", :foreign_key => "consumer_id", :order => "name"

  has_many :network_interfaces, :dependent => :destroy
  has_many :ip_addresses, :through => :network_interfaces

  validates_presence_of :name, :hardware_profile_id, :status_id
  
  validates_uniqueness_of :name
  validates_uniqueness_of :uniqueid, :allow_nil => true, :allow_blank => true
  
  validates_numericality_of :processor_socket_count, :only_integer => true, :greater_than_or_equal_to => 0, :allow_nil => true
  validates_numericality_of :processor_count,        :only_integer => true, :greater_than_or_equal_to => 0, :allow_nil => true
  validates_numericality_of :processor_core_count,   :only_integer => true, :greater_than_or_equal_to => 0, :allow_nil => true
  validates_numericality_of :os_processor_count,     :only_integer => true, :greater_than_or_equal_to => 0, :allow_nil => true
  validates_numericality_of :power_supply_count,     :only_integer => true, :greater_than_or_equal_to => 0, :allow_nil => true

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

  def self.default_search_attribute
    'name'
  end
 
  after_save :update_outlets
  
  def consumed_network_outlets
    network_outlets = []
    self.consumed_outlets.each { |outlet| network_outlets << outlet if outlet.producer.hardware_profile.outlet_type == "Network" }
    return network_outlets
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

        require 'generator'
        s = SyncEnumerator.new(available_outlet_names.keys.sort, outlet_needs_renaming)
        s.each do |name, outlet|
          # The two lists may not be the same length
          if name && outlet
            outlet.name = name
            outlet.save
          end
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

  def before_destroy
    raise "A node can not be destroyed that has database instances assigned to it." if !self.node_database_instance_assignments.nil? && self.node_database_instance_assignments.count > 0
  end
  
end
