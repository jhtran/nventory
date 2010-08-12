module VolumesHelper
  def volume_servers
    return Node.find(:all, :select => 'id, name', :order => 'name').map{|node| [node.name,node.id]}
  end
end
