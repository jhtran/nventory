class Outlet < ActiveRecord::Base
  acts_as_authorizable
  acts_as_audited
  
  named_scope :def_scope
  
  acts_as_reportable
  acts_as_commentable
  
  # FIXME: Network outlets should really be consumed by a NIC, not a
  # node, but that screws up the genericness of this model
  belongs_to :producer, :class_name => "Node", :foreign_key => "producer_id"
  belongs_to :consumer, :polymorphic => true
  validates_uniqueness_of :name, :scope => :producer_id
  validates_uniqueness_of :consumer_id, :scope => [:producer_id, :consumer_type], :allow_nil => true, :allow_blank => true
  validates_presence_of :name, :producer_id

  def before_create
    validates_producer
    validates_consumer_type if consumer
  end

  def before_update
    validates_consumer_type if consumer
  end

  def validate 
  end

  def validates_consumer_type
    unless Outlet.consumer_types.values.uniq.collect{|val| val.to_s}.include?(consumer.class.to_s)
      errors.add(:consumer_type, " consumer type incorrect.") 
      return false
    end
    # if this outlet has a consumer node, make sure said node isn't already over it's limit for this producer's service type
    outlet_type = self.producer.hardware_profile.outlet_type
    consumer_outlets_in_use = Outlet.find(:all, :include => {:producer=>{:hardware_profile=>{}}}, 
                                          :conditions => ["consumer_id = ? and hardware_profiles.outlet_type = ?",self.consumer.id,outlet_type])
    
    if outlet_type == 'Network'
      consumer = NetworkInterface.find(self.consumer_id)
      unless consumer_outlets_in_use.empty?
        if consumer_outlets_in_use.length >= consumer.node.number_of_physical_nics
          errors.add(:consumer_id, "does not have any available network ports")
          return false
        end
      end
    else
      consumer = Node.find(self.consumer_id)
      if outlet_type == 'Power'
        unless consumer_outlets_in_use.empty?
          if consumer_outlets_in_use.length >= consumer.power_supply_count || consumer.power_supply_count.nil? 
            errors.add(:consumer_id, "does not have any available power plugs")
            return false
          end
        end
      elsif outlet_type == 'Console'
        # Assume all nodes have one serial console port
        errors.add(:consumer_id, "does not have any available console ports") if consumer_outlets_in_use.length >= 1
        return false
      elsif outlet_type == 'Blade'
        if consumer_outlets_in_use.length >= 1
          errors.add(:consumer_id, "is already assigned to a blade enclosure #{consumer_outlets_in_use[0].producer.name}") 
          return false
        end
      end # if outlet_type == 'Power'
    end # if outlet_type == 'Network'
  end

  def validates_producer
    producer_outlets_in_use = Outlet.count(:all,:conditions => ["producer_id = ?" , producer.id])
    (if producer_outlets_in_use >= producer.hardware_profile.outlet_count
      errors.add(:producer_id, Outlet.outlet_types[producer.hardware_profile.outlet_type].tableize.humanize.downcase.pluralize + " has met or exceeded max capacity" )
      return false
    end) unless producer.hardware_profile.outlet_count == 0
  end
  
  def self.default_search_attribute
    'name'
  end

  def self.consumer_types
    { 'Network' => NetworkInterface,
      'Power' => Node,
      'Console' => Node,
      'Blade' => Node }
  end

  def self.outlet_types
    { 'Network' => 'Network Port',
      'Power' => 'Power Outlet',
      'Console' => 'Console Port',
      'Blade' => 'Blade Slot' }
  end

end
