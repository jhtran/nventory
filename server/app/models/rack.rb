class Rack < ActiveRecord::Base
  
  acts_as_paranoid
  acts_as_commentable
  
  has_one :datacenter_rack_assignment, :dependent => :destroy
  # has_one :through support was recently added to Rails
  # http://dev.rubyonrails.org/ticket/4756
  # Once that makes it into a version we can run this can get
  # uncommented and the datacenter method below can go away.
  #has_one :datacenter, :through => :datacenter_rack_assignment
  
  has_many :rack_node_assignments, :order => "position"
  has_many :nodes, :through => :rack_node_assignments, :conditions => 'rack_node_assignments.deleted_at IS NULL'
  
  validates_presence_of :name
  
  def self.default_search_attribute
    'name'
  end
 
  def u_height
    42
  end
  
  def used_u_height
    n = 0
    self.nodes.each do |node|
      n = n + node.hardware_profile.rack_size if !node.hardware_profile.rack_size.nil?
    end
    return n
  end
  
  def free_u_height
    self.u_height - self.used_u_height
  end
  
  # This can go away eventually, see above
  def datacenter
    if self.datacenter_rack_assignment
     return self.datacenter_rack_assignment.datacenter
    else
      return nil
    end
  end
  
  def before_destroy
    raise "A rack can not be destroyed that has nodes assigned to it." if self.rack_node_assignments.count > 0
  end
  
end
