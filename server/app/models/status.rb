class Status < ActiveRecord::Base
  acts_as_authorizable
  acts_as_audited
  
  named_scope :def_scope
  
  acts_as_reportable
  acts_as_commentable
  
  has_many :nodes
  
  validates_presence_of :name
  validates_uniqueness_of :name

  def destroy
    unless nodes.empty? 
      errors.add_to_base "Status \"#{name}\" still has nodes assigned to it"
      return false
    end
  end
  
  def self.default_search_attribute
    'name'
  end

  def before_destroy
  end
 
end
