class NetworkPort < ActiveRecord::Base
  acts_as_authorizable
  acts_as_audited
  named_scope :def_scope
  acts_as_reportable
  acts_as_commentable
  has_many :ip_address_network_port_assignments, :dependent => :destroy
  has_many :ip_addresses, :through => :ip_address_network_port_assignments
  validates_uniqueness_of :number, :scope => [:protocol]

  def self.protocols
    %w( tcp udp )
  end

  validates_inclusion_of :protocol, :in => self.protocols

  def self.default_search_attribute
    'number'
  end

  def node_count
    Node.count(:all, :joins => {:network_interfaces=>{:ip_addresses=>{:network_ports=>{}}}}, :conditions => "network_ports.id = '#{id}'")
  end

end
