class AccountGroupSelfGroupAssignment < ActiveRecord::Base
  acts_as_authorizable
  acts_as_audited
  
  named_scope :def_scope
  
  acts_as_reportable
  
  belongs_to :account_group, :foreign_key => 'account_group_id'
  belongs_to :self_group,  :foreign_key => 'self_group_id',  :class_name => 'AccountGroup'
  
  validates_presence_of :account_group_id, :self_group_id
  
  def self.default_search_attribute
    'assigned_at'
  end
 
  def before_create
    self.assigned_at ||= Time.now 
  end

  def after_validation
    add_virtual_assignments_to_parents
  end

 def before_destroy
    if !virtual_assignment?
      flag = []
      account_group.child_groups.each do |child|
        flag << child if  child.self_groups.include?(self_group)
      end
      unless (flag.empty?) || (flag.nil?)
        logger.debug "Converting real AGSGA to virtual and rejecting destruction"
        update_attributes(:virtual_assignment => true)
        return false
      else
        remove_parent_virtuals
      end
    else
      remove_parent_virtuals
    end
  end

  def add_virtual_assignments_to_parents
    account_group.all_parent_groups.each do |parent|
      logger.debug "Checking for existing AGSGA for parent #{parent.name} and self_group #{self_group.name}"
      if !AccountGroupSelfGroupAssignment.exists?(:account_group_id => parent.id, :self_group_id => self_group.id)
        logger.debug "  No existing AGSGA for parent #{parent.name} and self_group #{self_group.name}, creating"
        agsga = AccountGroupSelfGroupAssignment.new(:account_group_id => parent.id, :self_group_id => self_group.id, :virtual_assignment => true)
        if !agsga.save
          logger.debug "    Save of new AGSGA failed"
          return false
        end
      end
    end
  end

  def remove_virtual_assignments_from_parents(deleted_agsga=self)
    account_group.parent_groups.each do |parent|
      # Check if the self_group has reason to keep its assignment to this parent
      # self_group group due to other AGSGAs
      if parent.all_child_self_groups_except_agsga(deleted_agsga).include?(self_group)
        logger.debug "Leaving AGSGA from self_group #{self_group.name} to parent #{parent.name} due to other AGSGAs"
      else
        agsga = AccountGroupSelfGroupAssignment.find_by_account_group_id_and_self_group_id(parent.id, self_group.id)
        if agsga.virtual_assignment?
          logger.debug "Removing AGSGA from self_group #{self_group.name} to parent #{parent.name}"
          agsga.remove_virtual_assignments_from_parents(deleted_agsga)
          agsga.destroy
        end
      end
    end
  end

  def remove_parent_virtuals(ag=self.account_group,sg=self.self_group,excludes=[],depth=0)
    depth += 1
    # ask each parent group if they have a DIFF child group with that self_group, either exclude that parent or add to delete list
    to_delete = []
    ag.parent_groups.each do |parent|
      results = _build_exclude_delete(parent,ag,account_group,sg,excludes,depth)
      next if results.nil?
      results[:to_del].each { |to_del| to_delete << to_del } unless results[:to_del].nil?
      results[:excl].each { |excl| excludes << excl } unless results[:excl].nil?
    end

    # delete parent groups in the delete list
    to_delete.uniq.each do |del_ag|
      agsga = AccountGroupSelfGroupAssignment.find_by_account_group_id_and_self_group_id(del_ag.id, sg.id)
      unless excludes.include?(del_ag)
        if (defined?(agsga)) && (!agsga.nil?)
          if !agsga.virtual_assignment?
            excludes << agsga.account_group
            return
          else
            excludes << agsga.account_group
            #  Relied on using the acts_as_paranoid method to 'market an object as deleted' by setting timestamp to the 'deleted_at' field.
            #  However, with removal of acts_as_paranoid, now need a diff method
            AccountGroupSelfGroupAssignment.delete(agsga.id)
          end
        end
      else
      end
    end

    # Now loop through ng's parents again.  This time have it check 1 level higher (its parents)
    ag.parent_groups.each do |parent|
      unless (parent.parent_groups.nil?) || (parent.parent_groups.empty?)
        remove_parent_virtuals(parent,sg,excludes,depth)
      end
    end

    return true
  end # remove_parent_virtuals

  # Called on by remove_parent_virtuals only
  def _build_exclude_delete(parent,ag,account_group,sg,excludes,depth)
    return nil if excludes.include?(parent)
    build_del_list = {}
    build_del_list[:excl] = []
    build_del_list[:to_del] = []

    parent.child_groups.each do |child|
      # each parent should not check the child that initiated the inquiry so create a list of each
      # of its children except the one that initiated
      if child == ag
        agsga = AccountGroupSelfGroupAssignment.find_by_account_group_id_and_self_group_id(parent.id, sg.id)
        # If there aren't any other parents (relative to source agsga), means safe to delete
        if (parent.child_groups.size == 1)
          # if the parent agsga is a real assignment, don't delete it.
          if (defined?(agsga.virtual_assignment?)) && (!agsga.virtual_assignment?)
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
      # if the parent indeed has another childng with the self_group as a member, then we break the chain.  
      # meaning the parentng keeps its ng-to-self_group assoc as well as ITS parents.
      agsga_to_del = AccountGroupSelfGroupAssignment.find_by_account_group_id_and_self_group_id(parent.id, sg.id)
      if (child.self_groups.include?(sg))
        build_del_list[:excl] << parent
        unless (parent.parent_groups.nil?) || (parent.parent_groups.empty?)
          parent.parent_groups.each do |ppg|
            build_del_list[:excl] << ppg
          end
        end
        return build_del_list
      # OR if it is a real agsga and not a virtual, we should also exclude it from being deleted
      elsif defined?(agsga_to_del.virtual_assignment?) && (!agsga_to_del.virtual_assignment?)
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
