class LbPool < ActiveRecord::Base
  set_table_name 'node_groups'

  acts_as_commentable
  acts_as_reportable

  named_scope :def_scope, :joins => :lb_profile

  has_many  :vip_lb_pool_assignments
  has_many  :vips, :through => :vip_lb_pool_assignments

  has_many :lb_pool_node_assignments, :dependent => :destroy, :foreign_key => "node_group_id"
  has_many :nodes, :through => :lb_pool_node_assignments

  has_one :lb_profile, :dependent => :destroy, :foreign_key => 'lb_pool_id'

  validates_presence_of :name
  validates_uniqueness_of :name

  accepts_nested_attributes_for :lb_profile, :allow_destroy => true

  def self.default_search_attribute
    'name'
  end
end
