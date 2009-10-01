class UtilizationMetricName < ActiveRecord::Base
  named_scope :def_scope
  
  acts_as_reportable
  acts_as_commentable
  
  has_many :nodes
  
  validates_presence_of :name
  validates_uniqueness_of :name
  
  def self.default_search_attribute
    'name'
  end
 
end
