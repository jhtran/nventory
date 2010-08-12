class AccountGroupAuthzAssignment < ActiveRecord::Base
  acts_as_authorizable
  validates_presence_of :authz_id
  validates_presence_of :account_group_id
  validates_uniqueness_of :authz_id, :scope => :account_group_id

  acts_as_audited

  acts_as_reportable

  belongs_to :authz, :class_name => 'Account', :foreign_key => 'authz_id'
  belongs_to :account_group

  def before_create
    self.assigned_at ||= Time.now
  end

  def self.default_search_attribute
    'assigned_at'
  end
end
