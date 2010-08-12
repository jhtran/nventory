class IpAddress < ActiveRecord::Base
  acts_as_authorizable
  acts_as_audited
  
  named_scope :def_scope
  
  acts_as_reportable
  acts_as_commentable

  belongs_to :network_interface
  has_one :vip
  has_many :ip_address_network_port_assignments, :dependent => :destroy
  has_many :network_ports, :through => :ip_address_network_port_assignments
  # Fake belongs_to :node, :through => :network_interface
  # Rails doesn't support belongs_to, :through unfortunately
  delegate :node, :node=, :to => :network_interface

  # These constraints are duplicates of constraints imposed at the
  # database layer (see the relevant migration file for details).
  # These are here because they'll catch errors most of the time
  # (they're subject to race conditions, so they won't catch every
  # time), and when they do catch an error they provide a nicer error
  # message back to the user than if the error is caught at the database
  # layer.
  validates_presence_of :address, :address_type
  validates_format_of :address_type, :with => /\b(ipv4|ipv6)\b/

  def self.default_search_attribute
    'address'
  end
 
end
