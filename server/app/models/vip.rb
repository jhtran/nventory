class Vip < ActiveRecord::Base
  named_scope :def_scope

  acts_as_reportable
  acts_as_commentable

  belongs_to :load_balancer, :class_name => "Node"
  has_many :vip_lb_pool_assignments
  has_many :lb_pools, :through => :vip_lb_pool_assignments

  # These constraints are duplicates of constraints imposed at the
  # database layer (see the relevant migration file for details).
  # These are here because they'll catch errors most of the time
  # (they're subject to race conditions, so they won't catch every
  # time), and when they do catch an error they provide a nicer error
  # message back to the user than if the error is caught at the database
  # layer.
  validates_presence_of :name, :protocol, :port, :load_balancer
  validates_uniqueness_of :name, :ip_address
  validates_numericality_of :port
  validates_format_of :ip_address, :with => /\b(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b/
  validates_format_of :protocol, :with => /\b(tcp|udp|both)\b/

  def self.default_search_attribute
    'name'
  end
 
end
