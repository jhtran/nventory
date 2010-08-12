class DatabaseInstance < ActiveRecord::Base
  acts_as_authorizable
  acts_as_audited
  
  named_scope :def_scope
  
  acts_as_commentable
  
  has_one :node_database_instance_assignment, :dependent => :destroy
  
  validates_presence_of :name
  
  def self.default_search_attribute
    'name'
  end
 
end
