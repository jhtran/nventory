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
  has_many :parent_groups, :through => :assignments_as_child
  has_many :child_groups,  :through => :assignments_as_parent

  # This is used by the edit page in the view
  # http://lists.rubyonrails.org/pipermail/rails/2006-August/059801.html
  def child_group_ids
    child_groups.map(&:id)
  end
  def node_ids
    nodes.map(&:id)
  end

  has_many :node_group_node_assignments, :dependent => :destroy
  has_many :nodes, :through => :node_group_node_assignments

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
  
  def real_node_group_node_assignments
    node_group_node_assignments.reject { |ngna| ngna.virtual_assignment? }
  end
  def real_nodes
    real_node_group_node_assignments.collect { |ngna| ngna.node }
  end
  def virtual_node_group_node_assignments
    node_group_node_assignments.select { |ngna| ngna.virtual_assignment? }
  end
  def virtual_nodes
    virtual_node_group_node_assignments.collect { |ngna| ngna.node }
  end
  
  # This method ensures that the child groups of this node group are the
  # groups represented by the group ids passed to the method
  def set_child_groups(groupids)
    # First ensure that all of the specified assignments exist
    new_assignments = []
    groupids.each do |cgid|
      cg = NodeGroup.find(cgid)
      if !cg.nil? && !child_groups.include?(cg)
        assignment = NodeGroupNodeGroupAssignment.new(:parent_id => id,
                                                      :child_id  => cgid)
        new_assignments << assignment
      end
    end
    
    # Save any new assignments
    node_group_assignment_save_successful = true
    new_assignments.each do |assignment|
      if !assignment.save
        node_group_assignment_save_successful = false
        # Propagate the error from the assignment to ourself
        # so that the user gets some feedback as to the problem
        assignment.errors.each_full { |msg| errors.add(:child_group_ids, msg) }
      end
    end
    
    # Now remove any existing assignments that weren't specified
    assignments_as_parent.each do |assignment|
      if !groupids.include?(assignment.child_id)
        assignment.destroy
      end
    end
    
    node_group_assignment_save_successful
  end
  
  # This method ensures that the nodes of this node group are the
  # nodes represented by the node ids passed to the method
  def set_nodes(nodeids)
    # Have to be careful here to handle existing virtual assignments
    # properly.  If the user has specified a new node and there's an
    # existing virtual assignment we need to convert that into a real
    # assignment.  And when removing nodes that the user didn't
    # specify we don't want to remove virtual assignments.
    
    # First ensure that all of the specified assignments exist
    new_assignments = []
    nodeids.each do |nodeid|
      node = Node.find(nodeid)
      if !node.nil?
        assignment = NodeGroupNodeAssignment.find_by_node_group_id_and_node_id(id, nodeid)
        if assignment.nil?
          assignment = NodeGroupNodeAssignment.new(:node_group_id => id,
                                                   :node_id       => nodeid)
          new_assignments << assignment
        elsif assignment.virtual_assignment?
          assignment.update_attributes(:virtual_assignment => false)
        end
      end
    end
    
    # Save any new assignments
    node_assignment_save_successful = true
    new_assignments.each do |assignment|
      if !assignment.save
        node_assignment_save_successful = false
        # Propagate the error from the assignment to ourself
        # so that the user gets some feedback as to the problem
        assignment.errors.each_full { |msg| errors.add(:node_ids, msg) }
      end
    end
    
    # Now remove any existing assignments that weren't specified
    node_group_node_assignments.each do |assignment|
      if !nodeids.include?(assignment.node_id) && !assignment.virtual_assignment?
        assignment.destroy
      end
    end
    
    node_assignment_save_successful
  end
  
  def all_parent_groups(path=[])
    visited = []
    path << self
    
    self.parent_groups.each do |parent_group|
      # We try to prevent cycles from getting into the node group
      # hierarchy in the first place (see the circular reference
      # validation in NodeGroupNodeGroupAssignment) but a little safety check
      # seems like a good idea, otherwise this method would go into an
      # infinite loop in the face of a cycle.
      if path.include?(parent_group)
        raise "Loop detected in node group hierarchy, #{self.name} " +
          "has #{parent_group.name} as a parent, check #{parent_group.name} " +
          " for connections back to #{self.name}"
      end
      visited << parent_group
      visited.concat(parent_group.all_parent_groups(path))
    end
    
    visited
  end
  
  def all_child_groups(path=[])
    visited = []
    path << self
    
    self.child_groups.each do |child_group|
      # We try to prevent cycles from getting into the node group
      # hierarchy in the first place (see the circular reference
      # validation in NodeGroupNodeGroupAssignment) but a little safety check
      # seems like a good idea, otherwise this method would go into an
      # infinite loop in the face of a cycle.
      if path.include?(child_group)
        raise "Loop detected in node group hierarchy, #{self.name} " +
          "has #{child_group.name} as a child, check #{child_group.name} " +
          " for connections back to #{self.name}"
      end
      visited << child_group
      visited.concat(child_group.all_child_groups(path))
    end
    
    visited
  end
  
  def all_child_groups_except_ngnga(excluded_ngnga, path=[])
    visited = []
    path << self
    
    self.assignments_as_parent.each do |ngnga|
      if ngnga != excluded_ngnga
        # We try to prevent cycles from getting into the node group
        # hierarchy in the first place (see the circular reference
        # validation in NodeGroupNodeGroupAssignment) but a little safety check
        # seems like a good idea, otherwise this method would go into an
        # infinite loop in the face of a cycle.
        if path.include?(ngnga.child_group)
          raise "Loop detected in node group hierarchy, #{self.name} " +
            "has #{ngnga.child_group.name} as a child, check #{ngnga.child_group.name} " +
            " for connections back to #{self.name}"
        end
        visited << ngnga.child_group
        visited.concat(ngnga.child_group.all_child_groups_except_ngnga(excluded_ngnga, path))
      end
    end
    
    visited
  end
  
  def all_child_nodes
    child_nodes = {}
    nodes.each { |node| child_nodes[node] = true }
    all_child_groups.each do |group|
      group.nodes.each { |node| child_nodes[node] = true }
    end
    child_nodes.keys
  end
  
  def all_child_nodes_except_ngna(excluded_ngna)
    child_nodes = {}
    node_group_node_assignments.each do |ngna|
      if ngna != excluded_ngna
        child_nodes[ngna.node] = true
      end
    end
    all_child_groups.each do |group|
      group.node_group_node_assignments.each do |ngna|
        if ngna != excluded_ngna
          child_nodes[ngna.node] = true
        end
      end
    end
    child_nodes.keys
  end

  def all_child_nodes_except_ngnga(excluded_ngnga)
    child_nodes = {}
    nodes.each { |node| child_nodes[node] = true }
    all_child_groups_except_ngnga(excluded_ngnga).each do |group|
      group.nodes.each { |node| child_nodes[node] = true }
    end
    child_nodes.keys
  end
end

