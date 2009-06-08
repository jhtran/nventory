class LbPool < ActiveRecord::Base
  set_table_name 'node_groups'

  acts_as_commentable
  acts_as_reportable

  named_scope :def_scope, :conditions => 'lb_profile_id is not null'

  has_many  :vip_lb_pool_assignments
  has_many  :vips, :through => :vip_lb_pool_assignments

  has_many :lb_pool_node_assignments, :dependent => :destroy, :foreign_key => "node_group_id"
  has_many :nodes, :through => :lb_pool_node_assignments

  belongs_to :lb_profile

  validates_presence_of :name
  validates_uniqueness_of :name

  def self.default_search_attribute
    'name'
  end
end
