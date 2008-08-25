class Vip < ActiveRecord::Base

  acts_as_paranoid
  acts_as_commentable

  belongs_to :node_group
  has_many :datacenter_vip_assignments, :dependent => :destroy
  has_many :datacenters, :through => :datacenter_vip_assignments, :conditions => 'datacenter_vip_assignments.deleted_at IS NULL'

  # These constraints are duplicates of constraints imposed at the
  # database layer (see the relevant migration file for details).
  # These are here because they'll catch errors most of the time
  # (they're subject to race conditions, so they won't catch every
  # time), and when they do catch an error they provide a nicer error
  # message back to the user than if the error is caught at the database
  # layer.
  validates_presence_of :name
  validates_uniqueness_of :name

  def self.default_search_attribute
    'name'
  end
 
end
