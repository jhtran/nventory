class NodeDatabaseInstanceAssignment < ActiveRecord::Base
  
  acts_as_paranoid
  
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
