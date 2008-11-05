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
    if !remove_virtual_assignments_from_parents
      return false
    end

    # And if it is a non-virtual NGNA we need to determine if it should be
    # replaced with a virtual NGNA
    if !virtual_assignment? && node_group.all_child_nodes_except_ngna(self).include?(node)
      logger.debug "Converting real NGNA to virtual and rejecting destruction"
      #virtual_assignment = true
      update_attributes(:virtual_assignment => true)
      if !virtual_assignment?
        logger.warn "virtual_assignment is still false"
      end
      # Return false so the destruction is canceled
      return false
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
end
