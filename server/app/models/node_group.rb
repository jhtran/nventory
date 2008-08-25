class NodeGroup < ActiveRecord::Base

  acts_as_paranoid
  acts_as_commentable

  has_many :subnets

  # http://blog.hasmanythrough.com/2006/4/21/self-referential-through
  # First establish the relationship with the node group assignments
  has_many :assignments_as_parent,
           :foreign_key => 'parent_id',
           :class_name => 'NodeGroupNodeGroupAssignment',
           :dependent => :destroy
  has_many :assignments_as_child,
           :foreign_key => 'child_id',
           :class_name => 'NodeGroupNodeGroupAssignment',
           :dependent => :destroy
  # Then establish the relationship with the groups on the other end
  # of those assignments
  has_many :parent_groups, :through => :assignments_as_child, :conditions => 'node_group_node_group_assignments.deleted_at IS NULL'
  has_many :child_groups,  :through => :assignments_as_parent, :conditions => 'node_group_node_group_assignments.deleted_at IS NULL'

  # This is used by the edit page in the view
  # http://lists.rubyonrails.org/pipermail/rails/2006-August/059801.html
  def child_group_ids
    child_groups.map(&:id)
  end
  def node_ids
    nodes.map(&:id)
  end

  has_many :node_group_node_assignments, :dependent => :destroy
  has_many :nodes, :through => :node_group_node_assignments, :conditions => 'node_group_node_assignments.deleted_at IS NULL'

  # These constraints are duplicates of constraints imposed at the
  # database layer (see the relevant migration file for details).
  # These are here because they'll catch errors most of the time
  # (they're subject to race conditions, so they won't catch every
  # time), and when they do catch an error they provide a nicer error
  # message back to the user than if the error is caught at the database
  # layer.
  validates_presence_of :name
  validates_uniqueness_of :name

  def self.default_search_attribute
    'name'
  end
 
  def all_children(path=[])
    visited = [self]
    path.push(self)

    self.child_groups.each do |child_group|
      # We try to prevent cycles from getting into the node group
      # hierarchy in the first place (see the circular reference
      # validation in NodeGroupNodeGroupAssignment) but a little safety check
      # seems like a good idea, otherwise this method would go into an
      # infinite loop in the face of a cycle.
      if (path.include?(child_group))
        raise "Loop detected in node group hierarchy, #{self.name} " +
          "has #{child_group.name} as a child, check #{child_group.name} " +
          " for connections back to #{self.name}"
      end

      visited.push(child_group.all_children(path))
    end

    return visited
  end
end

