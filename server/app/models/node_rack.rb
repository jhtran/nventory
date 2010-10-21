class NodeRack < ActiveRecord::Base
  acts_as_authorizable
  acts_as_audited
  
  named_scope :def_scope
  
  acts_as_reportable
  acts_as_commentable
  
  has_one :datacenter_node_rack_assignment, :dependent => :destroy
  has_one :datacenter, :through => :datacenter_node_rack_assignment
  
  has_many :node_rack_node_assignments, :order => "position", :dependent => :destroy
  has_many :nodes, :through => :node_rack_node_assignments
  
  validates_presence_of :name
  validates_uniqueness_of :name
  validates_numericality_of :u_height, :only_integer => true, :greater_than => 0
  
  def self.default_search_attribute
    'name'
  end
 
  def get_u_height
    u_height || 42
  end
  
  def used_u_height
    n = 0
    self.nodes.each do |node|
      n = n + node.hardware_profile.rack_size if !node.hardware_profile.rack_size.nil?
    end
    return n
  end
  
  def free_u_height
    self.get_u_height - self.used_u_height
  end
  
  def before_destroy
    raise "A rack can not be destroyed that has nodes assigned to it." if self.node_rack_node_assignments.count > 0
  end
  
end
