class Drive < ActiveRecord::Base
  acts_as_authorizable
  acts_as_audited
  
  named_scope :def_scope
  
  acts_as_reportable
  acts_as_commentable

  belongs_to :storage_controller
  has_one :node, :through => :storage_controller
  has_many :volume_drive_assignments, :dependent => :destroy
  has_many :volumes, :through => :volume_drive_assignments

  validates_presence_of :name
  validates_numericality_of :size, :allow_nil => true

  def self.default_search_attribute
    'name'
  end

  def self.default_includes
    # The default display index_row columns
    []
  end

 
end
