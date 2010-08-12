class VolumeNodeAssignment < ActiveRecord::Base
  acts_as_authorizable
  acts_as_audited
  
  named_scope :def_scope
  
  acts_as_reportable
  
  belongs_to :volume
  belongs_to :node 
  
  validates_presence_of :volume_id, :node_id, :mount
  validates_uniqueness_of :volume_id, :scope => [:node_id, :mount]
  validates_uniqueness_of :mount, :scope => [:node_id]
  
  def self.default_search_attribute
    'assigned_at'
  end
 
  def before_create 
    self.assigned_at ||= Time.now 
  end
  
end
