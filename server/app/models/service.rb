class Service < ActiveRecord::Base
  set_table_name 'node_groups'
  named_scope :def_scope, :joins => :service_profile
  
  acts_as_commentable
  acts_as_reportable

  has_many :service_assignments_as_parent,
           :foreign_key => 'parent_id',
           :class_name => 'ServiceServiceAssignment',
           :dependent => :destroy
  has_many :service_assignments_as_child,
           :foreign_key => 'child_id',
           :class_name => 'ServiceServiceAssignment',
           :dependent => :destroy
  has_many :parent_services, :through => :service_assignments_as_child, :class_name => 'Service'
  has_many :child_services,  :through => :service_assignments_as_parent, :class_name => 'Service'

  has_many :node_group_node_assignments, :dependent => :destroy, :foreign_key => 'node_group_id'
  has_many :nodes, :through => :node_group_node_assignments 

  has_one :service_profile, :dependent => :destroy
  
  validates_presence_of :name
  validates_uniqueness_of :name
  validates_format_of :owner,
      :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i,
      :message => 'must be a valid email address',
      :allow_nil => true,
      :allow_blank => true

  accepts_nested_attributes_for :service_profile, :allow_destroy => true

  def child_service_ids
    child_services.map(&:id)
  end
  
  def self.default_search_attribute
    'name'
  end

  def recursive_child_services
    @all_child_services = []
    recurse_child_services(self)
    @all_child_services
  end

  def recurse_child_services(ng)
    @all_child_services << ng
    if ng.child_services.size > 0
      ng.child_services.each do |child|
        recurse_child_services(child)
      end
    end
  end

  def set_child_services(serviceids)
    # First ensure that all of the specified assignments exist
    new_assignments = []
    serviceids.each do |csid|
      cs = Service.find(csid)
      if !cs.nil? && !child_services.include?(cs)
        assignment = ServiceServiceAssignment.new(:parent_id => id,
                                                      :child_id  => csid)
        new_assignments << assignment
      end
    end
    
    # Save any new assignments
    service_assignment_save_successful = true
    new_assignments.each do |assignment|
      if !assignment.save
        service_assignment_save_successful = false
        # Propagate the error from the assignment to ourself
        # so that the user gets some feedback as to the problem
        assignment.errors.each_full { |msg| errors.add(:child_service_ids, msg) }
      end
    end
    
    # Now remove any existing assignments that weren't specified
    service_assignments_as_parent.each do |assignment|
      if !serviceids.include?(assignment.child_id)
        assignment.destroy
      end
    end
    
    service_assignment_save_successful
  end

  def to_node_group
    return NodeGroup.find(self.id)
  end
  
end
