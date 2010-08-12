class NetworkInterface < ActiveRecord::Base
  acts_as_authorizable
  acts_as_audited
  
  named_scope :def_scope
  
  acts_as_reportable
  acts_as_commentable

  belongs_to :node

  has_many :ip_addresses, :dependent => :destroy
  # This creates a polymorphic association to Outlet model which can be shared by other interface types such as power or console
  has_one :switch_port, :class_name => "Outlet", :as => :consumer, :dependent => :destroy

  # These constraints are duplicates of constraints imposed at the
  # database layer (see the relevant migration file for details).
  # These are here because they'll catch errors most of the time
  # (they're subject to race conditions, so they won't catch every
  # time), and when they do catch an error they provide a nicer error
  # message back to the user than if the error is caught at the database
  # layer.
  validates_presence_of :name

  def self.default_search_attribute
    'name'
  end
 
end
