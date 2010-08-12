class IpAddressNetworkPortAssignment < ActiveRecord::Base
  acts_as_authorizable
  acts_as_reportable
  named_scope :def_scope
  belongs_to :ip_address
  belongs_to :network_port
  validates_presence_of :ip_address_id, :network_port_id
  validates_uniqueness_of :network_port_id, :scope => [:ip_address_id]
  
  def self.default_search_attribute
    'assigned_at'
  end
 
  def before_create 
    self.assigned_at ||= Time.now 
  end

end
