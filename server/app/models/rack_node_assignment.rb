class RackNodeAssignment < ActiveRecord::Base
  
  acts_as_paranoid
  
  belongs_to :rack 
  belongs_to :node 
  
  acts_as_list :scope => :rack
  
  validates_presence_of :rack_id, :node_id
  validates_uniqueness_of :node_id
  
  def self.default_search_attribute
    'assigned_at'
  end
 
  def before_create 
    self.assigned_at ||= Time.now 
  end
  
end
