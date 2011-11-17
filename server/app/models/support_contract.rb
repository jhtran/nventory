class SupportContract < ActiveRecord::Base
  acts_as_authorizable
  acts_as_audited
  acts_as_reportable
  acts_as_commentable

  validates_uniqueness_of :name, :scope => :service_level

  named_scope :def_scope
  has_many :node_support_contract_assignments, :dependent => :destroy
  has_many :nodes, :through => :node_support_contract_assignments
  def self.default_search_attribute
    'name'
  end
end
