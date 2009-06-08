class VirtualAssignment < ActiveRecord::Base
  named_scope :def_scope
  
  acts_as_reportable
  
  belongs_to :virtual_host, :foreign_key => 'parent_id', :class_name => 'Node'
  belongs_to :virtual_guest,  :foreign_key => 'child_id',  :class_name => 'Node'
  
  validates_presence_of :parent_id, :child_id
  validates_uniqueness_of :parent_id, :scope => [:parent_id,:child_id]
  validates_uniqueness_of :child_id
  
  def self.default_search_attribute
    'assigned_at'
  end
 
  def before_create
    self.assigned_at ||= Time.now 
  end
  
  def validate
    # Don't allow loops in the connections, the connection hierarchy
    # should constitute a directed _acyclic_ graph.
    if virtual_host == virtual_guest
      errors.add :child_id, "virtual host and virtual guest cannot be the same"
    end
  end

  def after_validation
  end

  def before_destroy
  end

end
