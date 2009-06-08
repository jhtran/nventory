class Datacenter < ActiveRecord::Base
  named_scope :def_scope
  
  acts_as_reportable
  acts_as_commentable
  
  has_many :datacenter_rack_assignments
  has_many :racks, :through => :datacenter_rack_assignments
  
  validates_presence_of :name
  
  def self.default_search_attribute
    'name'
  end
 
  def before_destroy
    raise "A datacenter can not be destroyed that has racks assigned to it." if self.datacenter_rack_assignments.count > 0
  end
  
end
