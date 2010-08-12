class StorageController < ActiveRecord::Base
  acts_as_authorizable
  acts_as_audited
  
  named_scope :def_scope
  
  acts_as_reportable
  acts_as_commentable

  belongs_to :node
  has_many :drives, :dependent => :destroy

  validates_presence_of :name
  validates_numericality_of [:batteries,:cache_size], :allow_nil => true

  def self.default_search_attribute
    'name'
  end

  def self.default_includes
    # The default display index_row columns
    return [:node, :drives]
  end
 
end
