class NodeGroupNodeGroupAssignment < ActiveRecord::Base
  named_scope :def_scope
  
  acts_as_reportable
  
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
    if child_group == parent_group || child_group.all_child_groups.include?(parent_group) || parent_group.all_child_groups.include?(child_group)
      errors.add :child_id, "new child #{child_group.name} creates a loop in group hierarchy, check that group for connection back to #{parent_group.name}"
      return false
    end

    # 2nd wave of tests -- (Child Groups)
      # obtain parent's child groups and gauge each's depth
    pcgs_depth = {}
    parent_group.child_groups.each do |pcg|
      pcgs_depth[pcg] = 0
      cgs_results = _cgs_depth(pcg)
      cgs_results.each_pair { |k,v| pcgs_depth[k] = v }
    end
    # now check the child's child groups and gauge each's depth
    ccgs_depth = {}
    child_group.child_groups.each do |ccg|
      ccgs_depth[ccg] = 0
      cgs_results = _cgs_depth(ccg)
      cgs_results.each_pair { |k,v| ccgs_depth[k] = v }
    end

    ccgs_depth.keys.each do |cg| 
      if pcgs_depth[cg] 
        unless pcgs_depth[cg] == (ccgs_depth[cg] +=1)
          errors.add :child_id, "new child #{child_group.name} creates a loop in group hierarchy due to #{cg.name}, check that group for connection back to #{parent_group.name}"
          return false
        end
      end
    end

    # 2nd wave of tests -- (Parent Groups)
      # obtain parent's pARENT groups and gauge each's depth
    ppgs_depth = {}
    parent_group.parent_groups.each do |ppg|
      ppgs_depth[ppg] = 0
      pgs_results = _pgs_depth(ppg)
      pgs_results.each_pair { |k,v| ppgs_depth[k] = v }
    end
    # now check the parent's PARENT groups and gauge each's depth
    cpgs_depth = {}
    child_group.parent_groups.each do |cpg|
      cpgs_depth[cpg] = 0
      pgs_results = _pgs_depth(cpg)
      pgs_results.each_pair { |k,v| cpgs_depth[k] = v }
    end

    cpgs_depth.keys.each do |cg| 
      if ppgs_depth[cg] 
        unless ppgs_depth[cg] == (cpgs_depth[cg] +=1)
          errors.add :parent_id, "new parent #{parent_group.name} creates a loop in group hierarchy due to #{cg.name}, check that group for connection back to #{parent_group.name}"
          return false
        end
      end
    end
  end

  def _pgs_depth(ng,depth=0)
    depth += 1
    pgs_depth = {}
    ng.parent_groups.each do |pgs|
      pgs_depth[pgs] = depth
      pgs_results = _pgs_depth(pgs,depth)
      pgs_results.each_pair { |k,v| pgs_depth[k] = v }
    end
    return pgs_depth
  end

  def _cgs_depth(ng,depth=0)
    depth += 1
    cgs_depth = {}
    ng.child_groups.each do |cgs|
      cgs_depth[cgs] = depth
      cgs_results = _cgs_depth(cgs,depth)
      cgs_results.each_pair { |k,v| cgs_depth[k] = v }
    end
    return cgs_depth
  end
  private :_cgs_depth

  def after_validation
    # When a new NGNGA is created we need to walk up the parent tree and add
    # virtual NGNAs to each parent group for every child node of the new
    # NGNGA's child_group
    # This is done as an after_validation rather than an after_save so that,
    # if it fails, the new NGNGA won't be saved.  Thus the user is likely to
    # try again and we get a second chance to fix things.  If this was
    # implemented as after_save the user's NGNGA would get saved and they
    # might not realize this failed, or even if they did wouldn't have a way
    # to retry or fix it.
    add_virtual_assignments_to_parents
  end

  # When an NGNA is deleted we need to walk up the parent tree and remove
  # virtual NGNAs
  def before_destroy
    remove_parent_virts
  end
  
  def add_virtual_assignments_to_parents
    # We can wimp out of actually walking the tree here and operate on
    # all_parent_groups.  We avoid the explicit tree walking (which is done
    # by all_parent_groups) but might have to check more groups than we
    # would if we actually walked the tree if the child group has another real
    # assignment to a parent node.  If we walked the tree we could stop at
    # that point (as we would know that we inserted virtual
    # assignments above that parent when the NGNGA to that parent was
    # created).  And yes, in the time it took to write this comment I
    # probably could have written the tree walking code.  :)
    all_child_nodes = child_group.nodes
    logger.debug "child group #{child_group.name} has #{all_child_nodes.size} children"
    [parent_group, *parent_group.all_parent_groups].each do |parent|
      logger.debug "add_virtual_assignments_to_parents processing #{parent.name}"
      all_child_nodes.each do |node|
        logger.debug "Checking for existing NGNA for parent #{parent.name} and node #{node.name}"
        if !NodeGroupNodeAssignment.exists?(:node_group_id => parent.id, :node_id => node.id)
          logger.debug "  No existing NGNA for parent #{parent.name} and node #{node.name}, creating"
          NodeGroupNodeAssignment.create(:node_group_id => parent.id, :node_id => node.id, :virtual_assignment => true)
        end
      end
    end
  end
  
  def remove_virtual_assignments_from_parents(child_nodes_to_remove, deleted_ngnga=self)
    [parent_group, *parent_group.parent_groups].each do |parent|
      # Check if each node has a reason to keep its assignment to this parent
      # node group due to other NGNAs
      local_child_nodes_to_remove = child_nodes_to_remove.dup
      all_child_nodes = parent.all_child_nodes_except_ngnga(deleted_ngnga)
      child_nodes_to_remove.each do |child_node_to_remove|
        if all_child_nodes.include?(child_node_to_remove)
          logger.debug "Excluding #{child_node_to_remove.name} from removal from #{parent.name} due to other NGNAs"
          local_child_nodes_to_remove.delete(child_node_to_remove)
        end
      end
      
      local_child_nodes_to_remove.each do |node|
        ngna = NodeGroupNodeAssignment.find_by_node_group_id_and_node_id(parent.id, node.id)
        if ngna.virtual_assignment?
          logger.debug "Removing NGNA from node #{node.name} to parent #{parent.name}"
          #ngna.remove_virtual_assignments_from_parents(local_child_nodes_to_remove, deleted_ngnga)
          ngna.destroy
        end
      end
    end
  end
  
  def remove_parent_virts
    child_ng_nodes = child_group.nodes
    destroy_candidates = []
    parent_group.node_group_node_assignments.each do |ngna|
      if ngna.virtual_assignment?
        destroy_candidates << ngna if child_ng_nodes.include?(ngna.node)
      end
    end
    other_child_group_nodes = []
    parent_group.child_groups.each do |other_child_group|
      next if other_child_group == child_group
      other_child_group.nodes.each { |ocg_node| other_child_group_nodes << ocg_node }
    end
    destroy_candidates.each do |candidate|
      candidate.destroy unless other_child_group_nodes.include?(candidate.node)
    end
  end # def remove_parent_virts
end
