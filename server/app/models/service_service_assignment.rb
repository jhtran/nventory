class ServiceServiceAssignment < ActiveRecord::Base
  acts_as_authorizable
  acts_as_audited
  
  named_scope :def_scope
  
  acts_as_reportable
  
  belongs_to :parent_service, :foreign_key => 'parent_id', :class_name => 'Service'
  belongs_to :child_service,  :foreign_key => 'child_id',  :class_name => 'Service'
  
  validates_presence_of :parent_id, :child_id
  validates_uniqueness_of :parent_id, :scope => [:parent_id,:child_id]
  
  def self.default_search_attribute
    'assigned_at'
  end
 
  def before_create
    self.assigned_at ||= Time.now 
  end
  
  def validate
    # Don't allow loops in the connections, the connection hierarchy
    # should constitute a directed _acyclic_ graph.
    if child_service == parent_service || child_service.recursive_child_services.include?(parent_service)
      errors.add :child_id, "new child #{child_service.name} creates a loop in group hierarchy, check that group for connection back to #{parent_service.name}"
    end
  end

  def after_validation
  end

  def before_destroy
  end

  def parent_name
    parent_service.name
  end
  
end
