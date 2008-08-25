class NodeGroupNodeGroupAssignment < ActiveRecord::Base

  acts_as_paranoid
  
  belongs_to :parent_group, :foreign_key => 'parent_id', :class_name => 'NodeGroup'
  belongs_to :child_group,  :foreign_key => 'child_id',  :class_name => 'NodeGroup'
  
  validates_presence_of :parent_id, :child_id
  
  def self.default_search_attribute
    'assigned_at'
  end
 
  def before_create 
    self.assigned_at ||= Time.now 
  end
  
  def validate
    # Don't allow loops in the connections, the connection hierarchy
    # should constitute a directed _acyclic_ graph.
    if child_group.all_children.include?(parent_group)
      errors.add :child_id, "new child #{child_group.name} creates a loop in group hierarchy, check that group for connection back to #{parent_group.name}"
    end
  end

  def before_create 
    self.assigned_at ||= Time.now 
  end
  
end
