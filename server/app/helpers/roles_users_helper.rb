module RolesUsersHelper
  def role_classify(role,nolink=false)
    if role.authorizable.nil? && role.authorizable_type.nil?
      roleclass= 'Global'
      roletag = roleclass
    elsif role.authorizable.nil? && !role.authorizable_type.nil?
      roleclass = 'Class'
      if nolink 
        roletag = "#{role.authorizable_type} Class"
      else
        roletag = link_to("#{role.authorizable_type} Class", url_for(:controller => role.authorizable_type.tableize))
      end
    elsif role.authorizable && role.authorizable_type
      roleclass = 'instance'
      # when node_group inheritance from parent node_group, should link if the srcobj(currentview) isn't the authorized role obj (parent_group)
      if nolink
        roletag =  "#{role.authorizable.send(role.authorizable.class.default_search_attribute)} (#{role.authorizable.class.to_s.capitalize} Instance)"
      else
        roletag = link_to( "#{role.authorizable.send(role.authorizable.class.default_search_attribute)}",role.authorizable)
      end
    else
      roleclass = 'unknown'
    end
  end
end
