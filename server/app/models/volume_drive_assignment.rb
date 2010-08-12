class VolumeDriveAssignment < ActiveRecord::Base
  acts_as_authorizable
  acts_as_audited
  
  named_scope :def_scope
  
  acts_as_reportable
  
  belongs_to :volume
  belongs_to :drive
  
  validates_presence_of :volume_id, :drive_id
  #validates_uniqueness_of :volume_id, :scope => :drive_id
  
  def self.default_search_attribute
    'assigned_at'
  end
 
  def before_create 
    self.assigned_at ||= Time.now 
  end
  
end
