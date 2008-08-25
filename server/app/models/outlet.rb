class Outlet < ActiveRecord::Base
  
  acts_as_paranoid
  acts_as_commentable
  
  # FIXME: Network outlets should really be consumed by a NIC, not a
  # node, but that screws up the genericness of this model
  belongs_to :producer, :class_name => "Node", :foreign_key => "producer_id"
  belongs_to :consumer, :class_name => "Node", :foreign_key => "consumer_id"
  
  validates_presence_of :name, :producer_id
  
  def validate 
    if !self.consumer_id.nil? and self.consumer_id > 0
      
      # if this outlet has a consumer node, make sure said node isn't already over it's limit for this producer's service type
      
      outlet_type = self.producer.hardware_profile.outlet_type
      current_outlets_in_use_by_consumer = Outlet.find_all_by_consumer_id(self.consumer_id)
      current_outlets_in_use_by_consumer.delete(self);
      current_network_outlets_in_use_by_consumer = []
      current_power_outlets_in_use_by_consumer = []
      current_console_outlets_in_use_by_consumer = []
      
      current_outlets_in_use_by_consumer.each do |outlet|
        if outlet.producer.hardware_profile.outlet_type == 'Network'
          current_network_outlets_in_use_by_consumer << outlet
        elsif outlet.producer.hardware_profile.outlet_type == 'Power'
          current_power_outlets_in_use_by_consumer << outlet
        elsif outlet.producer.hardware_profile.outlet_type == 'Console'
          current_console_outlets_in_use_by_consumer << outlet
        end
      end
      
      if outlet_type == 'Network'
        errors.add(:consumer_id, "does not have any available network ports") if current_network_outlets_in_use_by_consumer.length >= Node.find(self.consumer_id).number_of_physical_nics
      elsif outlet_type == 'Power'
        errors.add(:consumer_id, "does not have any available power plugs") if current_power_outlets_in_use_by_consumer.length >= Node.find(self.consumer_id).power_supply_count
      elsif outlet_type == 'Console'
        # Assume all nodes have one serial console port
        errors.add(:consumer_id, "does not have any available console ports") if current_console_outlets_in_use_by_consumer.length >= 1
      end
      
    end
  end
  
  def self.default_search_attribute
    'name'
  end
 
end
