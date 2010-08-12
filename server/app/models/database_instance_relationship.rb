class DatabaseInstanceRelationship < ActiveRecord::Base
  acts_as_authorizable
  acts_as_audited
  
  named_scope :def_scope
  
  belongs_to :from, :class_name => "DatabaseInstance", :foreign_key => "from_id"
  belongs_to :to,   :class_name => "DatabaseInstance", :foreign_key => "to_id"
  
  validates_presence_of :name, :from_id, :to_id
  
  def self.names_allowed
    ['Master', 'Slave']
  end
  
  def self.default_search_attribute
    'name'
  end
 
  def before_create 
    self.assigned_at ||= Time.now 
  end
  
end
