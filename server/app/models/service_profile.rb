class ServiceProfile < ActiveRecord::Base
  named_scope :def_scope
  acts_as_reportable
  acts_as_commentable

  belongs_to :service

  # for some reason, when using accepts_nested_attributes_for, cannot validate presence
  #validates_presence_of :service_id
  #validates_uniqueness_of :service_id
  #validates_inclusion_of :external, :in => [true, false]
  #validates_inclusion_of :pciscope, :in => [true, false]

  def self.default_search_attribute
    'dev_url'
  end
end
