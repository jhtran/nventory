class NodeSupportContractAssignment < ActiveRecord::Base
  acts_as_authorizable
  acts_as_audited
  acts_as_reportable

  named_scope :def_scope
  belongs_to :node
  belongs_to :support_contract

  validates_uniqueness_of :support_contract_id, :scope => :node_id

  def before_create
    self.assigned_at ||= Time.now
  end
end
