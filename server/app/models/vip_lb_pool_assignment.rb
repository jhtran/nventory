class VipLbPoolAssignment < ActiveRecord::Base
  acts_as_audited
  acts_as_authorizable
  acts_as_reportable
  acts_as_commentable 

  named_scope :def_scope

  belongs_to :vip
  belongs_to :lb_pool

  validates_uniqueness_of :vip_id, :scope => :lb_pool_id

  def self.default_search_attribute
    'assigned_at'
  end

  def before_create
    self.assigned_at ||= Time.now
  end

end
