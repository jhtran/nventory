class Status < ActiveRecord::Base
  
  acts_as_paranoid
  acts_as_commentable
  
  has_many :nodes
  
  validates_presence_of :name
  validates_uniqueness_of :name
  
  def self.default_search_attribute
    'name'
  end
 
end
