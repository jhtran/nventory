class DatacenterVipAssignment < ActiveRecord::Base
  
  acts_as_paranoid
  
  belongs_to :datacenter
  belongs_to :vip
  
  validates_presence_of :datacenter_id, :vip_id
  validates_numericality_of :priority, :only_integer => true, :allow_nil => true
  
  def self.default_search_attribute
    'assigned_at'
  end
 
  def before_create 
    self.assigned_at ||= Time.now 
  end
  
end
