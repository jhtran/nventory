# Defines named roles for users that may be applied to
# objects in a polymorphic fashion. For example, you could create a role
# "moderator" for an instance of a model (i.e., an object), a model class,
# or without any specification at all.
class Role < ActiveRecord::Base
  acts_as_authorizable
  named_scope :def_scope
  has_many :roles_users, :dependent => :delete_all
  has_many :users, :through => :roles_users, :source => :account_group
  belongs_to :authorizable, :polymorphic => true

  def validate
    
  end

  def self.role_names
    %w(admin creator updater destroyer)
  end

  validates_inclusion_of :name, :in => self.role_names

end
