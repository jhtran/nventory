class Node < ActiveRecord::Base
  
  acts_as_paranoid
  acts_as_commentable
  
  has_one :rack_node_assignment, :dependent => :destroy
  # has_one :through support was recently added to Rails
  # http://dev.rubyonrails.org/ticket/4756
  # Once that makes it into a version we can run this can get
  # uncommented and the rack method below can go away.
  #has_one :rack, :through => :rack_node_assignment
  
  belongs_to :hardware_profile
  belongs_to :operating_system
  belongs_to :preferred_operating_system,
             :class_name => 'OperatingSystem',
             :foreign_key => 'preferred_operating_system_id'
  belongs_to :status
  
  has_many :node_group_node_assignments, :dependent => :destroy
  has_many :node_groups, :through => :node_group_node_assignments, :conditions => 'node_group_node_assignments.deleted_at IS NULL'
  
  has_many :node_database_instance_assignments
  has_many :database_instances, :through => :node_database_instance_assignments, :conditions => 'node_database_instance_assignments.deleted_at IS NULL'
  
  # :dependent => :destroy?
  has_many :produced_outlets, :class_name => "Outlet", :foreign_key => "producer_id", :order => "name"
  has_many :consumed_outlets, :class_name => "Outlet", :foreign_key => "consumer_id", :order => "name"

  has_many :network_interfaces, :dependent => :destroy
  has_many :ip_addresses, :through => :network_interfaces, :conditions => 'network_interfaces.deleted_at IS NULL'

  validates_presence_of :name, :hardware_profile_id, :status_id
  
  validates_uniqueness_of :name
  # Rails 2.0 has an :allow_blank, but we have to make our own with :if for Rails 1.2
  validates_uniqueness_of :uniqueid, :allow_nil => true, :if => Proc.new { |u| !u.uniqueid.nil? && !u.uniqueid.empty? }
    
  validates_numericality_of :processor_socket_count, :only_integer => true, :allow_nil => true
  validates_numericality_of :processor_count,        :only_integer => true, :allow_nil => true
  validates_numericality_of :processor_core_count,   :only_integer => true, :allow_nil => true
  validates_numericality_of :os_processor_count,     :only_integer => true, :allow_nil => true
  validates_numericality_of :power_supply_count,     :only_integer => true, :allow_nil => true

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

  # FIXME: Dry this up.
  def validate 
    if !self.processor_socket_count.nil? and self.processor_socket_count < 0
      errors.add(:processor_socket_count, "can not be negative") 
    end 
    
    if !self.processor_count.nil? and self.processor_count < 0
      errors.add(:processor_count, "can not be negative") 
    end 
    
    if !self.processor_core_count.nil? and self.processor_core_count < 0
      errors.add(:processor_core_count, "can not be negative") 
    end 
    
    if !self.os_processor_count.nil? and self.os_processor_count < 0
      errors.add(:os_processor_count, "can not be negative") 
    end 
    
    if !self.power_supply_count.nil? and self.power_supply_count < 0
      errors.add(:power_supply_count, "can not be negative") 
    end
  end

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
  
  def update_outlets
    # this method will look at our hardware profile and make sure we have the correct number of outlets realized in the database.
    if !self.hardware_profile.outlet_count.nil? and self.hardware_profile.outlet_count > 0 and self.produced_outlets.length != self.hardware_profile.outlet_count
      if self.produced_outlets.length < self.hardware_profile.outlet_count
        # We need to add outlets
        how_many_to_add = self.hardware_profile.outlet_count - self.produced_outlets.length
        how_many_to_add.times { self.add_new_outlet }
      else
        # We need to remove outlets
        how_many_to_remove = self.produced_outlets.length - self.hardware_profile.outlet_count
        how_many_to_remove.times { self.remove_bottom_outlet }
      end
    end
  end
  
  def add_new_outlet
    # Find out how many outlets we currently have
    count = self.produced_outlets(true).length + 1
    o = Outlet.new
    o.name = count.to_s
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

  # This can go away eventually, see above
  def rack
    if self.rack_node_assignment
     return self.rack_node_assignment.rack
    else
      return nil
    end
  end
  
  def before_destroy
    raise "A node can not be destroyed that has database instances assigned to it." if !self.node_database_instance_assignments.nil? && self.node_database_instance_assignments.count > 0
  end
  
end
