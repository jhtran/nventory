class HardwareProfile < ActiveRecord::Base
  acts_as_authorizable
  acts_as_audited
  
  named_scope :def_scope
  
  acts_as_reportable
  acts_as_commentable
  
  has_many :nodes
  
  validates_presence_of :name
  validates_uniqueness_of :name
  
  validates_numericality_of :rack_size,               :only_integer => true, :greater_than_or_equal_to => 0, :allow_nil => true
  validates_numericality_of :processor_socket_count,  :only_integer => true, :greater_than_or_equal_to => 0, :allow_nil => true
  validates_numericality_of :processor_count,         :only_integer => true, :greater_than_or_equal_to => 0, :allow_nil => true
  validates_numericality_of :outlet_count,            :only_integer => true, :greater_than_or_equal_to => 0, :allow_nil => true
  validates_numericality_of :estimated_cost,          :only_integer => true, :greater_than_or_equal_to => 0, :allow_nil => true
  validates_numericality_of :power_supply_slot_count, :only_integer => true, :greater_than_or_equal_to => 0, :allow_nil => true
  validates_numericality_of :power_supply_count,      :only_integer => true, :greater_than_or_equal_to => 0, :allow_nil => true
  validates_numericality_of :power_consumption,       :only_integer => true, :greater_than_or_equal_to => 0, :allow_nil => true
  validates_numericality_of :nics,                    :only_integer => true, :greater_than_or_equal_to => 0, :allow_nil => true

  # If an outlet type has been specified make sure it is one of the allowed types
  validates_inclusion_of :outlet_type,
                         :in => Outlet.outlet_types.keys,
                         :allow_nil => true,
                         :allow_blank => true,
                         :message => "not one of the allowed outlet " +
                            "types: #{Outlet.outlet_types.keys.join(',')}"

  def self.default_search_attribute
    'name'
  end
 
end
