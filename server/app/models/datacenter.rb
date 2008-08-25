class Datacenter < ActiveRecord::Base
  
  acts_as_paranoid
  acts_as_commentable
  
  has_many :datacenter_rack_assignments
  has_many :racks, :through => :datacenter_rack_assignments, :conditions => 'datacenter_rack_assignments.deleted_at IS NULL'
  
  has_many :datacenter_vip_assignments
  has_many :vips, :through => :datacenter_vip_assignments, :conditions => 'datacenter_vip_assignments.deleted_at IS NULL'
  
  validates_presence_of :name
  
  def self.default_search_attribute
    'name'
  end
 
  def before_destroy
    raise "A datacenter can not be destroyed that has racks assigned to it." if self.datacenter_rack_assignments.count > 0
    raise "A datacenter can not be destroyed that has VIPs assigned to it." if self.datacenter_vip_assignments.count > 0
  end
  
end
