class StorageController < ActiveRecord::Base
  named_scope :def_scope
  
  acts_as_reportable
  acts_as_commentable

  belongs_to :node

  validates_presence_of :name

  def self.default_search_attribute
    'name'
  end
 
end
