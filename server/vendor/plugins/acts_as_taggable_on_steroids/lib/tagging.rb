class Tagging < ActiveRecord::Base #:nodoc:
  named_scope :def_scope
  acts_as_authorizable
  acts_as_audited
  belongs_to :tag
  belongs_to :taggable, :polymorphic => true

  validates_uniqueness_of :tag_id, :scope => [:taggable_id,:taggable_type]

  def self.default_search_attribute
    'created_at'
  end
  
  def after_destroy
    if Tag.destroy_unused
      if tag.taggings.count.zero?
        tag.destroy
      end
    end
  end
end
