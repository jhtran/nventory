class LbPoolNodeAssignment < ActiveRecord::Base
  acts_as_authorizable
  acts_as_audited
  
  named_scope :def_scope
  set_table_name 'node_group_node_assignments'
  
  acts_as_reportable
  
  belongs_to :node
  belongs_to :lb_pool, :foreign_key => 'node_group_id'
  
  validates_presence_of :node_id, :node_group_id
  validates_uniqueness_of :node_id, :scope => :node_group_id

  def validate
  end

  def node_not_lb
    return true unless self.lb_pool.vips.collect{|vip| vip.load_balancer}.includes?(node)
  end

  def self.default_search_attribute
    'assigned_at'
  end
 
  def before_create 
    self.assigned_at ||= Time.now 
  end
  
  def before_destroy
  end
  
end
