class DatacenterRackAssignment < ActiveRecord::Base
  
  acts_as_paranoid
  
  belongs_to :datacenter
  belongs_to :rack 
  
  validates_presence_of :datacenter_id, :rack_id
  validates_uniqueness_of :rack_id
  
  def self.default_search_attribute
    'assigned_at'
  end
 
  def before_create 
    self.assigned_at ||= Time.now 
  end
  
end
