Graffiti.class_eval do
  acts_as_authorizable
  acts_as_audited
  named_scope :def_scope
  def self.default_search_attribute
   'name'
  end
  def to_s
    name
  end
end
