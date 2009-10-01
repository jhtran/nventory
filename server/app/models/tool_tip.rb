class ToolTip < ActiveRecord::Base
  named_scope :def_scope
  validates_presence_of :model
  validates_presence_of :attr
  validates_uniqueness_of :attr, :scope => :model
  
  def self.default_search_attribute
    'attr'
  end
end
