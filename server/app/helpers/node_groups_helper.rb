module NodeGroupsHelper

  def add_node_groups_tag(parent_or_child)
    if allow_perm(@node_group,['updater']) 
      return ";Element.show('add_child_link')" if parent_or_child == :child
      return ";Element.show('add_parent_link')" if parent_or_child == :parent
    end
  end

  def add_services_tag(parent_or_child)
    if allow_perm(@node_group,['updater']) 
      return ";Element.show('add_child_service_link')" if parent_or_child == :child
      return ";Element.show('add_parent_service_link')" if parent_or_child == :parent
    end
  end

  def add_nodes_tag
    if allow_perm(@node_group,['updater'])
      return ";Element.show('add_node_link')" 
    end
  end

  def add_vips_tag
    if allow_perm(@node_group,['updater'])
      return ";Element.show('add_vip_link')" 
    end
  end

  def node_group_contacts(node_group)
    content = []
    content << ('<p><strong>' + tooltip(ServiceProfile,:contact,'Emergency Contact') + ':</strong><br />')
    unless node_group.service_profile.contact.nil? 
      contacts = []
      node_group.service_profile.contact.split(',').each do |login| 
        if (SSO_AUTH_SERVER && login !~ /@/) 
          contacts << link_to(login,"https://#{SSO_AUTH_SERVER}/users?login=#{login}") 
        elsif (login =~ /@/) 
          contacts << (mail_to login) 
        else 
          contacts << login
        end 
      end # node_group.service_profile.contact.split(',').each do |login|
      ( content << '<p>' + contacts.join(', ') + '</p>' ) unless contacts.empty?
    end # unless node_group.service_profile.contact.nil?
    return content
  end # def node_group_contacts(node_group)

end
