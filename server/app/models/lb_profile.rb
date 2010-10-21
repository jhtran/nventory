class LbProfile < ActiveRecord::Base
  acts_as_authorizable
  acts_as_audited
  
  named_scope :def_scope

  acts_as_reportable
  acts_as_commentable

  belongs_to :lb_pool

  #validates_uniqueness_of :lb_pool_id
  validates_presence_of  :port, :protocol, :lbmethod
  validates_format_of :port, :with => /\b\d+\b/
  validates_format_of :protocol, :with => /\b(tcp|udp|both)\b/
  validates_format_of :lbmethod, :with => /\b(round_robin|ratio_member|dynamic_ratio|fastest_member|least_conn_member|observed_member|predictive_member|lb_method_round_robin|lb_method_ratio_member|lb_method_least_connection_member|lb_method_observed_member|lb_method_predictive_member|lb_method_ratio_node_address|lb_method_least_connection_node_address|lb_method_fastest_node_address|lb_method_observed_node_address|lb_method_predictive_node_address|lb_method_dynamic_ratio|lb_method_fastest_app_response|lb_method_least_sessions|lb_method_dynamic_ratio_member|lb_method_l3_addr)\b/

  def self.default_search_attribute
    'port'
  end

  def self.healthchecks
    healthchecks = self.find(:all,:select => 'DISTINCT healthcheck').map(&:healthcheck).compact.reject(&:blank?)
    healthchecks << 'http' unless healthchecks.include?('http')
    return healthchecks
  end
end
