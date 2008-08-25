class Subnet < ActiveRecord::Base

  acts_as_paranoid
  acts_as_commentable

  belongs_to :node_group

  # These constraints are duplicates of constraints imposed at the
  # database layer (see the relevant migration file for details).
  # These are here because they'll catch errors most of the time
  # (they're subject to race conditions, so they won't catch every
  # time), and when they do catch an error they provide a nicer error
  # message back to the user than if the error is caught at the database
  # layer.
  validates_presence_of :network, :netmask, :broadcast
  validates_uniqueness_of :network

  def self.default_search_attribute
    'network'
  end
 
end
