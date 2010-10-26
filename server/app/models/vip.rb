class Vip < ActiveRecord::Base
  acts_as_audited
  acts_as_authorizable
  
  named_scope :def_scope

  acts_as_reportable
  acts_as_commentable

  belongs_to :load_balancer, :class_name => "Node"
  has_many :vip_lb_pool_assignments
  has_many :lb_pools, :through => :vip_lb_pool_assignments
  belongs_to :ip_address, :dependent => :destroy
  has_many :node_group_vip_assignments, :dependent => :destroy
  has_many :node_groups, :through => :node_group_vip_assignments
  # These constraints are duplicates of constraints imposed at the
  # database layer (see the relevant migration file for details).
  # These are here because they'll catch errors most of the time
  # (they're subject to race conditions, so they won't catch every
  # time), and when they do catch an error they provide a nicer error
  # message back to the user than if the error is caught at the database
  # layer.
  validates_presence_of :name, :protocol, :port
  validates_uniqueness_of :name
#  validates_uniqueness_of :load_balancer_id , :scope => :ip_address_id
  validates_numericality_of :port
  validates_format_of :protocol, :with => /\b(tcp|udp|both)\b/

  accepts_nested_attributes_for :ip_address, :allow_destroy => true

  def self.default_search_attribute
    'name'
  end
 
  def nodes
    lb_pools.collect{|lb_pool| lb_pool.nodes}.flatten
  end

  def real_node_group_vip_assignments
    node_group_vip_assignments.reject { |ngna| ngna.virtual_assignment? }
  end
  def real_node_groups
    real_node_group_vip_assignments.collect { |ngna| ngna.node_group }
  end
  def recursive_real_node_groups
    results = []
    real_node_group_vip_assignments.each do |rngna|
      results << rngna.node_group
      rngna.node_group.child_groups.each do |rngcg|
        results << rngcg
      end
    end
    results
  end
  def virtual_node_group_vip_assignments
    node_group_vip_assignments.select { |ngna| ngna.virtual_assignment? }
  end
  def virtual_node_groups
    virtual_ngnas.collect { |ngna| ngna.node_group }
  end
 
end
