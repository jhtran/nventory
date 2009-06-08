class NodeDatabaseInstanceAssignment < ActiveRecord::Base
  named_scope :def_scope
  
  acts_as_reportable
  
  belongs_to :node
  belongs_to :database_instance
  
  validates_presence_of :node_id, :database_instance_id
  validates_uniqueness_of :database_instance_id
  
  def self.default_search_attribute
    'assigned_at'
  end
 
  def before_create 
    self.assigned_at ||= Time.now 
  end

end
