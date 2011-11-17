class HardwareLifecycle < ActiveRecord::Base
  acts_as_authorizable
  acts_as_audited

  named_scope :def_scope

  belongs_to :node

  def self.default_search_attribute
    'node_id'
  end
end
