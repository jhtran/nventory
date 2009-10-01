class NodeGroupNodeAssignment < ActiveRecord::Base

  
  acts_as_reportable
  
  belongs_to :node
  belongs_to :node_group 
 
  belongs_to :service, :foreign_key => 'node_group_id'
  
  validates_presence_of :node_id, :node_group_id
  validates_uniqueness_of :node_id, :scope => :node_group_id

  def self.default_search_attribute
    'assigned_at'
  end
 
  def before_create 
    self.assigned_at ||= Time.now 
  end
  
  def after_validation
    # When a new NGNA is created we need to walk up the parent tree and add
    # virtual NGNAs to each parent group
    # This is done as an after_validation rather than an after_save so that,
    # if it fails, the new NGNA won't be saved.  Thus the user is likely to
    # try again and we get a second chance to fix things.  If this was
    # implemented as after_save the user's NGNA would get saved and they
    # might not realize this failed, or even if they did wouldn't have a way
    # to retry or fix it.
    add_virtual_assignments_to_parents
  end
  
  def before_destroy
    # FIXME: Ideally we'd prevent outside entities from deleting virtual
    # assignments without some level of extra confirmation.  That's been
    # added in the GUI for now, but doesn't protect us from XML users.
    
    # When an NGNA is deleted we need to walk up the parent tree and remove
    # virtual NGNAs
    #if !remove_virtual_assignments_from_parents
    #  return false
    #end

    # if it is a non-virtual (real) NGNA we need to determine if it should be
    # replaced with a virtual NGNA
    if !virtual_assignment? 
      flag = []
      node_group.child_groups.each do |child|
        flag << child if  child.nodes.include?(node)
      end
      unless (flag.empty?) || (flag.nil?)
        logger.debug "Converting real NGNA to virtual and rejecting destruction"
        update_attributes(:virtual_assignment => true)
        return false
      else
        remove_parent_virtuals
      end
    else
      remove_parent_virtuals
    end
  end
  
  # Recursively ensure that each parent of this NGNA's node group has a
  # NGNA to this NGNA's node
  def add_virtual_assignments_to_parents
    # We can wimp out of actually walking the tree here and operate on
    # all_parent_groups.  We avoid the explicit tree walking (which is done
    # by all_parent_groups) but might have to check more groups than we
    # would if we actually walked the tree if the node has another real
    # assignment to a parent node.  If we walked the tree we could stop at
    # that point (as we would know that we inserted virtual
    # assignments above that parent when the NGNA to that parent was
    # created).  And yes, in the time it took to write this comment I
    # probably could have written the tree walking code.  :)
    node_group.all_parent_groups.each do |parent|
      logger.debug "Checking for existing NGNA for parent #{parent.name} and node #{node.name}"
      if !NodeGroupNodeAssignment.exists?(:node_group_id => parent.id, :node_id => node.id)
        logger.debug "  No existing NGNA for parent #{parent.name} and node #{node.name}, creating"
        ngna = NodeGroupNodeAssignment.new(:node_group_id => parent.id, :node_id => node.id, :virtual_assignment => true)
        if !ngna.save
          logger.debug "    Save of new NGNA failed"
          return false
        end
      end
    end
  end
  
  # Remove virtual assignments for this NGNA's node from each of this NGNA's
  # node group's parents recursively, unless the node should have a virtual
  # assignment to that parent node group due to other NGNAs.
  def remove_virtual_assignments_from_parents(deleted_ngna=self)
    node_group.parent_groups.each do |parent|
      # Check if the node has reason to keep its assignment to this parent
      # node group due to other NGNAs
      if parent.all_child_nodes_except_ngna(deleted_ngna).include?(node)
        logger.debug "Leaving NGNA from node #{node.name} to parent #{parent.name} due to other NGNAs"
      else
        ngna = NodeGroupNodeAssignment.find_by_node_group_id_and_node_id(parent.id, node.id)
        if ngna.virtual_assignment?
          logger.debug "Removing NGNA from node #{node.name} to parent #{parent.name}"
          ngna.remove_virtual_assignments_from_parents(deleted_ngna)
          ngna.destroy
        end
      end
    end
  end

  # remove all the virtuals from parents, prior to destroying the object
  def remove_parent_virtuals(ng=self.node_group,nd=self.node,excludes=[],depth=0)
    depth += 1
    # ask each parent group if they have a DIFF child group with that node, either exclude that parent or add to delete list
    to_delete = []
    ng.parent_groups.each do |parent|
      results = _build_exclude_delete(parent,ng,node_group,nd,excludes,depth)
      next if results.nil?
      results[:to_del].each { |to_del| to_delete << to_del } unless results[:to_del].nil?
      results[:excl].each { |excl| excludes << excl } unless results[:excl].nil?
    end

    # delete parent groups in the delete list
    to_delete.uniq.each do |del_ng|
      ngna = NodeGroupNodeAssignment.find_by_node_group_id_and_node_id(del_ng.id, nd.id)
      unless excludes.include?(del_ng)
        if (defined?(ngna)) && (!ngna.nil?)
          if !ngna.virtual_assignment?
            excludes << ngna.node_group
            return
          else
            excludes << ngna.node_group
            #  Relied on using the acts_as_paranoid method to 'market an object as deleted' by setting timestamp to the 'deleted_at' field.
            #  However, with removal of acts_as_paranoid, now need a diff method
            NodeGroupNodeAssignment.delete(ngna.id)
          end
        end
      else
      end
    end

    # Now loop through ng's parents again.  This time have it check 1 level higher (its parents)
    ng.parent_groups.each do |parent|
      unless (parent.parent_groups.nil?) || (parent.parent_groups.empty?)
        remove_parent_virtuals(parent,nd,excludes,depth)
      end
    end

    return true
  end # remove_parent_virtuals

  # Called on by remove_parent_virtuals only 
  def _build_exclude_delete(parent,ng,node_group,nd,excludes,depth)
    return nil if excludes.include?(parent)
    build_del_list = {}
    build_del_list[:excl] = []
    build_del_list[:to_del] = []
    
    parent.child_groups.each do |child|
      # each parent should not check the child that initiated the inquiry so create a list of each
      # of its children except the one that initiated
      if child == ng
        ngna = NodeGroupNodeAssignment.find_by_node_group_id_and_node_id(parent.id, nd.id)
        # If there aren't any other parents (relative to source ngna), means safe to delete
        if (parent.child_groups.size == 1)
          # if the parent ngna is a real assignment, don't delete it.
          if (defined?(ngna.virtual_assignment?)) && (!ngna.virtual_assignment?)
            build_del_list[:excl] << parent
            return build_del_list
          elsif 
            build_del_list[:to_del] << parent
            return build_del_list
          end
        else # more child groups to process
          next
        end
      end
      # if the parent indeed has another childng with the node as a member, then we break the chain.  
      # meaning the parentng keeps its ng-to-node assoc as well as ITS parents.
      ngna_to_del = NodeGroupNodeAssignment.find_by_node_group_id_and_node_id(parent.id, nd.id)
      if (child.nodes.include?(nd))
        build_del_list[:excl] << parent
        unless (parent.parent_groups.nil?) || (parent.parent_groups.empty?)
          parent.parent_groups.each do |ppg|
            build_del_list[:excl] << ppg
          end
        end
        return build_del_list
      # OR if it is a real ngna and not a virtual, we should also exclude it from being deleted
      elsif defined?(ngna_to_del.virtual_assignment?) && (!ngna_to_del.virtual_assignment?)
        build_del_list[:excl] << parent
        unless (parent.parent_groups.nil?) || (parent.parent_groups.empty?)
          parent.parent_groups.each do |ppg|
            build_del_list[:excl] << ppg
          end
        end
        return build_del_list
      else
        build_del_list[:to_del] << parent
      end
    end
    return build_del_list
  end
  private :_build_exclude_delete

end 
