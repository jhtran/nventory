class LbProfile < ActiveRecord::Base
  named_scope :def_scope

  acts_as_reportable
  acts_as_commentable

  belongs_to :lb_pool

  #validates_uniqueness_of :lb_pool_id
  validates_presence_of  :port, :protocol, :lbmethod
  validates_format_of :port, :with => /\b\d+\b/
  validates_format_of :protocol, :with => /\b(tcp|udp|both)\b/
  validates_format_of :lbmethod, :with => /\b(round_robin|ratio_member|dynamic_ratio|fastest_member|least_conn_member|observed_member|predictive_member)\b/

  def self.default_search_attribute
    'port'
  end

  def self.healthchecks
    healthchecks = self.find(:all,:select => 'DISTINCT healthcheck').map(&:healthcheck).compact.reject(&:blank?)
    healthchecks << 'http' unless healthchecks.include?('http')
    return healthchecks
  end
end
