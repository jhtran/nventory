module ModelExtensions

  public

  def get_assocs(type = :belongs_to)
    aggregate_objs = self.reflect_on_all_associations(type)
    aggregate_objs.select{|m| m.name != :users}.map{|m| m.klass}
  end 

  def attrs
    excludes = %w(audits accepted_roles created_at updated_at users id)
    attrs = []
    self.column_names.each do |column|
      next if excludes.include?(column)
      attrs << [column.sub(/_id$/,''),column]
    end
    return attrs
  end

end
