# The table that links roles with users (generally named RoleUser.rb)
class RolesUser < ActiveRecord::Base
  acts_as_authorizable
  acts_as_audited
  named_scope :def_scope
  belongs_to :account_group
  belongs_to :role
  serialize :attrs

  def self.default_search_attribute
    'created_at'
  end

  def self.default_includes
    [:account_group]
  end
end
