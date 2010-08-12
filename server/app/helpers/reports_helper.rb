module ReportsHelper
  def links_to_requiredtags
    %w(business_unit services environment tier).collect{|tagn| link_to(tagn,Tag.find_by_name(tagn))}.join(', ')
  end

  def build_ng_list(node,type,selectlist)
    results = NodeGroup.find(:all,:joins => {:nodes => {},:taggings => {:tag =>{}}}, :conditions => ['tags.name = ? and nodes.id = ?',type.to_s,node.id])
    return results.collect{|ng| link_to ng.name,ng}.join(',') unless results.empty?
    basename = "#{node.name}_#{type}".sub(/\W/,'')
    content = "<div id='add_#{basename}'>\n"
    content << "#{link_to_function 'Assign', "Element.show('#{basename}_form');Element.hide('add_#{basename}')"}\n"
    content << "</div>\n"
    content << "<div id=#{basename}_form>\n"
    content << "#{form_remote_tag :url => url_for(:controller => 'node_group_node_assignments', :action => :create, :div => basename, :refcontroller => 'reports')}\n"
    content << "#{select_tag 'node_group_node_assignment[node_group_id]', options_for_select(selectlist.collect{|ng| [ng.name,ng.id]})}\n"
    content << "#{hidden_field_tag 'node_group_node_assignment[node_id]', node.id}\n"
    content << "#{submit_tag 'Assign'}\n</form>\n"
    content << "</div>\n"
    content << "<div id='#{basename}'></div>\n"
    content << "#{javascript_tag "Element.hide('#{basename}_form')"}\n"
    return content
  end
end
