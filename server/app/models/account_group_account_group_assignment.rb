class AccountGroupAccountGroupAssignment < ActiveRecord::Base
  acts_as_authorizable
  acts_as_audited
  
  named_scope :def_scope
  
  acts_as_reportable
  
  belongs_to :parent_group, :foreign_key => 'parent_id', :class_name => 'AccountGroup'
  belongs_to :child_group,  :foreign_key => 'child_id',  :class_name => 'AccountGroup'
  
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
        unless (ppgs_depth[cg] +=1) == cpgs_depth[cg]
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
    add_virtual_assignments_to_parents
  end

  def before_destroy
    remove_parent_virts
  end

  def add_virtual_assignments_to_parents
    all_self_groups = child_group.self_groups
    logger.debug "child group #{child_group.name} has #{all_self_groups.size} children"
    [parent_group, *parent_group.all_parent_groups].each do |parent|
      logger.debug "add_virtual_assignments_to_parents processing #{parent.name}"
      all_self_groups.each do |self_group|
        logger.debug "Checking for existing AGSGA for parent #{parent.name} and self_group #{self_group.name}"
        if !AccountGroupSelfGroupAssignment.exists?(:account_group_id => parent.id, :self_group_id => self_group.id)
          logger.debug "  No existing AGSGA for parent #{parent.name} and self_group #{self_group.name}, creating"
          AccountGroupSelfGroupAssignment.create(:account_group_id => parent.id, :self_group_id => self_group.id, :virtual_assignment => true)
        end
      end
    end
  end

  def remove_virtual_assignments_from_parents(self_groups_to_remove, deleted_agaga=self)
    [parent_group, *parent_group.parent_groups].each do |parent|
      # Check if each self group has a reason to keep its assignment to this parent
      # account group due to other AGSGAs
      local_self_groups_to_remove = self_groups_to_remove.dup
      all_self_groups = parent.all_self_groups_except_agaga(deleted_agaga)
      self_groups_to_remove.each do |child_self_group_to_remove|
        if all_self_groups.include?(child_self_group_to_remove)
          logger.debug "Excluding #{child_self_group_to_remove.name} from removal from #{parent.name} due to other AGSGAs"
          local_self_groups_to_remove.delete(child_self_group_to_remove)
        end
      end

      local_self_groups_to_remove.each do |self_group|
        agsga = AccountGroupSelfGroupAssignment.find_by_account_group_id_and_self_group_id(parent.id, self_group.id)
        if agsga.virtual_assignment?
          logger.debug "Removing AGSGA from self_group #{self_group.name} to parent #{parent.name}"
          agsga.destroy
        end
      end
    end
  end

  def remove_parent_virts
    child_ag_self_groups = child_group.self_groups
    destroy_candidates = []
    parent_group.assignments_as_self_group_parent.each do |agsga|
      if agsga.virtual_assignment?
        destroy_candidates << agsga if child_ag_self_groups.include?(agsga.self_group)
      end
    end
    other_child_group_self_groups = []
    parent_group.child_groups.each do |other_child_group|
      next if other_child_group == child_group
      other_child_group.self_groups.each { |ocg_self_group| other_child_group_self_groups << ocg_self_group }
    end
    destroy_candidates.each do |candidate|
      candidate.destroy unless other_child_group_self_groups.include?(candidate.self_group)
    end
  end # def remove_parent_virts

end
