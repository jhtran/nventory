class DatacenterNodeRackAssignment < ActiveRecord::Base
  acts_as_authorizable
  acts_as_audited
  
  named_scope :def_scope
  
  acts_as_reportable
  
  belongs_to :datacenter
  belongs_to :node_rack 
  
  validates_presence_of :datacenter_id, :node_rack_id
  validates_uniqueness_of :node_rack_id
  
  def self.default_search_attribute
    'assigned_at'
  end
 
  def before_create 
    self.assigned_at ||= Time.now 
  end
  
end
