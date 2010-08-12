class AccountGroup < ActiveRecord::Base
  named_scope :def_scope, :conditions => "account_groups.name not like '%.self%'"
  named_scope :self_scope, :conditions => "account_groups.name like '%.self%'"
  acts_as_authorized_user
  acts_as_authorizable
  acts_as_audited
  acts_as_taggable
  acts_as_commentable
  acts_as_reportable

  validates_uniqueness_of :name

  has_one :account_group_authz_assignment, :dependent => :destroy
  has_one :authz, :through => :account_group_authz_assignment

  has_many :assignments_as_parent,
           :foreign_key => 'parent_id',
           :class_name => 'AccountGroupAccountGroupAssignment',
           :dependent => :destroy
  has_many :assignments_as_child,
           :foreign_key => 'child_id',
           :class_name => 'AccountGroupAccountGroupAssignment',
           :dependent => :destroy
  has_many :parent_groups, :through => :assignments_as_child
  has_many :child_groups,  :through => :assignments_as_parent

  has_many :assignments_as_self_group_parent,
           :foreign_key => 'account_group_id',
           :class_name => 'AccountGroupSelfGroupAssignment',
           :dependent => :destroy
  has_many :assignments_as_self_group,
           :foreign_key => 'self_group_id',
           :class_name => 'AccountGroupSelfGroupAssignment',
           :dependent => :destroy
  has_many :self_groups, :through => :assignments_as_self_group_parent
  has_many :self_group_parents,  :through => :assignments_as_self_group, :source => :account_group

  def self.default_search_attribute
    'name'
  end

  def self.default_includes
    # The default display index_row columns
    []
  end

  def child_group_ids
    child_groups.map(&:id)
  end

  def set_child_groups(groupids)
    # First ensure that all of the specified assignments exist
    new_assignments = []
    groupids.each do |cgid|
      cg = AccountGroup.find(cgid)
      if !cg.nil? && !child_groups.include?(cg)
        assignment = AccountGroupAccountGroupAssignment.new(:parent_id => id,
                                                      :child_id  => cgid)
        new_assignments << assignment
      end
    end

    # Save any new assignments
    account_group_assignment_save_successful = true
    new_assignments.each do |assignment|
      if !assignment.save
        account_group_assignment_save_successful = false
        # Propagate the error from the assignment to ourself
        # so that the user gets some feedback as to the problem
        assignment.errors.each_full { |msg| errors.add(:child_group_ids, msg) }
      end
    end

    # Now remove any existiag assignments that weren't specified
    assignments_as_parent.each do |assignment|
      if !groupids.include?(assignment.child_id)
        assignment.destroy
      end
    end

    account_group_assignment_save_successful
  end

  def all_parent_groups(ag=self,list={},depth=0)
    depth += 1
    ag.parent_groups.each do |parent_group|
      if list[depth].kind_of?(Array)
        list[depth] << parent_group
      else
        list[depth] = [parent_group]
      end
      all_parent_groups(parent_group, list, depth) unless parent_group.parent_groups.empty?
    end

    # Startiag with top level, ensure that value doesn't exist on lower levels
    num_keys = list.keys.last
    list.keys.each do |level|
      count = level
      while count + 1 <= num_keys
        list[level].each do |parent_ag|
          if list[count + 1].include?(parent_ag)
            raise "Loop detected in account group hierarchy, #{parent_ag.name}\n"
          end
        end
        count += 1
      end
    end

    return list.values.flatten
  end

  def all_child_groups(ag=self,list={},depth=0)
    depth += 1
    ag.child_groups.each do |child_group|
      if list[depth].kind_of?(Array)
        list[depth] << child_group
      else
        list[depth] = [child_group]
      end
      all_child_groups(child_group, list, depth) unless child_group.child_groups.empty?
    end

    # Startiag with top level, ensure that value doesn't exist on lower levels
    num_keys = list.keys.last
    list.keys.each do |level|
      count = level
      while count + 1 <= num_keys
        list[level].each do |child_ag|
          if list[count + 1].include?(child_ag)
            raise "Loop detected in account group hierarchy, #{child_ag.name}\n"
          end
        end
        count += 1
      end
    end

    return list.values.flatten
  end

  def all_self_groups
    all_child_groups.collect(&:self_groups).flatten.uniq + self_groups
  end

  def all_child_groups_except_agaga(excluded_agaga, path=[])
    visited = []
    path << self

    self.assignments_as_parent.each do |agaga|
      if agaga != excluded_agaga
        # We try to prevent cycles from gettiag into the account group
        # hierarchy in the first place (see the circular reference
        # validation in AccountGroupAccountGroupAssignment) but a little safety check
        # seems like a good idea, otherwise this method would go into an
        # infinite loop in the face of a cycle.
        if path.include?(agaga.child_group)
          raise "Loop detected in account group hierarchy, #{self.name} " +
            "has #{agaga.child_group.name} as a child, check #{agaga.child_group.name} " +
            " for connections back to #{self.name}"
        end
        visited << agaga.child_group
        visited.concat(agaga.child_group.all_child_groups_except_agaga(excluded_agaga, path))
      end
    end

    visited
  end

  def all_self_groups_except_agsga(excluded_agsga)
    self_groups = {}
    assignments_as_self_group_parent.each do |agsga|
      if agsga != excluded_agsga
        self_groups[agsga.self_group] = true
      end
    end
    all_child_groups.each do |group|
      group.assignments_as_self_group_parent.each do |agsga|
        if agsga != excluded_agsga
          self_groups[agsga.self_group] = true
        end
      end
    end
    self_groups.keys
  end

  def all_self_groups_except_agaga(excluded_agaga)
    self_groups = {}
    real_self_groups.each { |self_group| self_groups[self_group] = true }
    all_child_groups_except_agaga(excluded_agaga).each do |group|
      group.self_groups.each { |self_group| self_groups[self_group] = true }
    end
    self_groups.keys
  end

  def all_self_group_parents
    all = []
    self_group_parents.each do |ag|
      all << ag
      ag.all_parent_groups.each do |pg|
        all << pg
      end
    end
    return all.uniq
  end

  def real_account_group_self_group_assignments
    assignments_as_self_group_parent.find(:all,:include => {:self_group =>{}}, :conditions => "account_group_self_group_assignments.virtual_assignment is null or account_group_self_group_assignments.virtual_assignment != 1")
  end

  def real_self_groups
    real_account_group_self_group_assignments.collect { |agsga| agsga.self_group unless agsga.self_group.nil? }.compact
  end

  def real_self_groups_names
    real_account_group_self_group_assignments.collect { |agsga| agsga.self_group.name unless agsga.self_group.nil? }.compact.join(",")
  end

  def virtual_account_group_self_group_assignments
    assignments_as_self_group_parent.find(:all,:include => {:account_group =>{},:self_group =>{}}, :conditions => "account_group_self_group_assignments.virtual_assignment = 1")
  end

  def virtual_self_groups
    virtual_account_group_self_group_assignments.collect { |agsga| agsga.self_group }
  end

  def virtual_self_groups_names
    virtual_account_group_self_group_assignments.collect { |agsga| agsga.self_group.name }.join(",")
  end

  def real_self_group_account_group_assignments
    assignments_as_self_group.find(:all,:include => {:self_group =>{}}, :conditions => "account_group_self_group_assignments.virtual_assignment is null or account_group_self_group_assignments.virtual_assignment != 1")
  end

  def real_account_groups
    real_self_group_account_group_assignments.collect { |agsga| agsga.account_group }
  end

  def recursive_real_account_groups
    results = []
    real_self_group_account_group_assignments.each do |ragsga|
      results << ragsga.account_group
      ragsga.account_group.child_groups.each do |ragcg|
        results << ragcg
      end
    end
    results
  end

  def virtual_self_group_account_group_assignments
    assignments_as_self_group.select { |agsga| agsga.virtual_assignment? }
  end

  def virtual_account_groups
    virtual_self_group_account_group_assignments.collect { |agsga| agsga.account_group }
  end

  def set_self_groups(self_groupids)
    # First ensure that all of the specified assignments exist
    new_assignments = []
    sel_groupids.each do |self_groupid|
      self_group = AccountGroup.find(self_groupid)
      if !self_group.nil?
        assignment = AccountGroupSelfGroupAssignment.find_by_account_group_id_and_self_group_id(id, self_groupid)
        if assignment.nil?
          assignment = AccountGroupSelfGroupAssignment.new(:account_group_id => id,
                                                   :self_group_id       => self_groupid)
          new_assignments << assignment
        elsif assignment.virtual_assignment?
          assignment.update_attributes(:virtual_assignment => false)
        end
      end
    end

    # Save any new assignments
    self_group_assignment_save_successful = true
    new_assignments.each do |assignment|
      if !assignment.save
        self_group_assignment_save_successful = false
        # Propagate the error from the assignment to ourself
        # so that the user gets some feedback as to the problem
        assignment.errors.each_full { |msg| errors.add(:self_group_ids, msg) }
      end
    end

    # Now remove any existing assignments that weren't specified
    assignments_as_self_group_parent.each do |assignment|
      if !self_groupids.include?(assignment.self_group_id) && !assignment.virtual_assignment?
        assignment.destroy
      end
    end

    self_group_assignment_save_successful
  end

end
