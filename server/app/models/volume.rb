class Volume < ActiveRecord::Base
  acts_as_authorizable
  acts_as_audited
  
  named_scope :def_scope
  
  acts_as_reportable
  acts_as_commentable
  
  belongs_to :volume_server, :foreign_key => 'volume_server_id', :class_name => 'Node'
  has_many :volume_drive_assignments, :dependent => :destroy
  has_many :drives, :through => :volume_drive_assignments
  has_many :volume_node_assignments, :dependent => :destroy
  has_many :nodes, :through => :volume_node_assignments
  
  #validates_presence_of :name, :volume_type
  #validates_uniqueness_of :name, :scope => [:volume_type, :volume_server_id] if :volume_server_id
  validates_numericality_of :capacity, :allow_nil => true
  
  def self.default_search_attribute
    'name'
  end

  def self.volume_types
    return %w(ext2 ext3 ext4 nfs smb ufs hfs lvm raid)
  end
 
  def before_destroy
    raise "A volume can not be destroyed that has nodes assigned to it." if self.volume_node_assignments.count > 0
  end
  
end
