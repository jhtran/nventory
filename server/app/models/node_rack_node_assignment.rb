class NodeRackNodeAssignment < ActiveRecord::Base
  acts_as_authorizable
  acts_as_audited
  
  named_scope :def_scope
  
  acts_as_reportable
  
  belongs_to :node_rack 
  belongs_to :node 
  
  acts_as_list :scope => :node_rack
  
  validates_presence_of :node_rack_id, :node_id
  validates_uniqueness_of :node_id

  def validate
    if node.virtual_guest?
      errors.add(:node, "#{node.name} is a #{node.virtualarch} virtual guest therefore cannot be assigned to a physical rack space\n")
      return false
    end
  end
  
  def self.default_search_attribute
    'assigned_at'
  end
 
  def before_create 
    self.assigned_at ||= Time.now 
  end
  
end
