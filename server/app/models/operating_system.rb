class OperatingSystem < ActiveRecord::Base
  named_scope :def_scope
  
  acts_as_reportable
  acts_as_commentable
  
  has_many :nodes
  has_many :nodes_as_preferred_os,
           :class_name => 'Node',
           :foreign_key => 'preferred_operating_system_id'
  
  validates_presence_of :name

  def self.default_search_attribute
    'name'
  end
 
end
