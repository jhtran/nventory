class HardwareProfile < ActiveRecord::Base
  
  acts_as_paranoid
  acts_as_commentable
  
  has_many :nodes
  
  validates_presence_of :name
  validates_uniqueness_of :name
  
  validates_numericality_of :rack_size,               :only_integer => true, :allow_nil => true
  validates_numericality_of :processor_socket_count,  :only_integer => true, :allow_nil => true
  validates_numericality_of :processor_count,         :only_integer => true, :allow_nil => true
  validates_numericality_of :outlet_count,            :only_integer => true, :allow_nil => true
  validates_numericality_of :estimated_cost,          :only_integer => true, :allow_nil => true
  validates_numericality_of :power_supply_slot_count, :only_integer => true, :allow_nil => true
  validates_numericality_of :power_supply_count,      :only_integer => true, :allow_nil => true
  validates_numericality_of :power_consumption,       :only_integer => true, :allow_nil => true
  validates_numericality_of :nics,                    :only_integer => true, :allow_nil => true

  OUTLET_TYPES = ['','Power','Network','Console']
  def self.allowed_outlet_types
    return OUTLET_TYPES
  end
  
  # If an outlet type has been specified make sure it is one of the
  # allowed types
  validates_inclusion_of :outlet_type,
                         :in => OUTLET_TYPES,
                         :allow_nil => true,
                         :message => "not one of the allowed outlet " +
                            "types: #{OUTLET_TYPES.join(',')}"

  # FIXME: Dry this up.
  def validate 
    if !self.rack_size.nil? and self.rack_size < 0
      errors.add(:rack_size, "can not be negative") 
    end
    
    if !self.processor_socket_count.nil? and self.processor_socket_count < 0
      errors.add(:processor_socket_count, "can not be negative") 
    end 
    
    if !self.processor_count.nil? and self.processor_count < 0
      errors.add(:processor_count, "can not be negative") 
    end 
    
    if !self.outlet_count.nil? and self.outlet_count < 0
      errors.add(:outlet_count, "can not be negative") 
    end 
    
    if !self.estimated_cost.nil? and self.estimated_cost < 0
      errors.add(:estimated_cost, "can not be negative") 
    end
    
    if !self.power_supply_slot_count.nil? and self.power_supply_slot_count < 0
      errors.add(:power_supply_slot_count, "can not be negative") 
    end
    
    if !self.power_supply_count.nil? and self.power_supply_count < 0
      errors.add(:power_supply_count, "can not be negative") 
    end
    
    if !self.power_consumption.nil? and self.power_consumption < 0
      errors.add(:power_consumption, "can not be negative") 
    end
    
    if !self.nics.nil? and self.nics < 0
      errors.add(:nics, "can not be negative") 
    end
  end
  
  def self.default_search_attribute
    'name'
  end
 
end
