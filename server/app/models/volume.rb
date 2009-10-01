class Volume < ActiveRecord::Base
  named_scope :def_scope
  
  acts_as_reportable
  acts_as_commentable
  
  belongs_to :volume_server, :foreign_key => 'volume_server_id', :class_name => 'Node'
  has_many :volume_node_assignments
  has_many :nodes, :through => :volume_node_assignments
  
  validates_presence_of :name, :volume_type, :volume_server_id
  validates_uniqueness_of :name, :scope => [:volume_type, :volume_server_id]
  
  def self.default_search_attribute
    'name'
  end
 
  def before_destroy
    raise "A volume can not be destroyed that has nodes assigned to it." if self.volume_node_assignments.count > 0
  end
  
end
