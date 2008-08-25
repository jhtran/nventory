class NodeGroupNodeAssignment < ActiveRecord::Base

  acts_as_paranoid
  
  belongs_to :node
  belongs_to :node_group 
  
  validates_presence_of :node_id, :node_group_id

  def self.default_search_attribute
    'assigned_at'
  end
 
  def before_create 
    self.assigned_at ||= Time.now 
  end
  
end
