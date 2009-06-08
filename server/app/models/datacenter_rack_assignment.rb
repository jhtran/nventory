class DatacenterRackAssignment < ActiveRecord::Base
  named_scope :def_scope
  
  acts_as_reportable
  
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
