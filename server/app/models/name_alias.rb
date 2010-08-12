class NameAlias < ActiveRecord::Base
  acts_as_authorizable
  acts_as_audited
  
  named_scope :def_scope

  acts_as_reportable
  acts_as_commentable

  belongs_to :source, :polymorphic => true
  validates_uniqueness_of :name, :scope => [:source_id, :source_type]
  validates_presence_of :source, :source_id
  
  def self.default_search_attribute
    'name'
  end
end
