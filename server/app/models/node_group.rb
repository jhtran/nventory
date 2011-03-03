class NodeGroup < ActiveRecord::Base
  acts_as_authorizable
  acts_as_audited
  acts_as_taggable 
  is_graffitiable 
  named_scope :def_scope
  
  acts_as_commentable
  acts_as_reportable

  has_many :subnets

  # http://blog.hasmanythrough.com/2006/4/21/self-referential-through
  # First establish the relationship with the node group assignments
  has_many :assignments_as_parent,
           :foreign_key => 'parent_id',
           :class_name => 'NodeGroupNodeGroupAssignment',
           :dependent => :destroy
  has_many :assignments_as_child,
           :foreign_key => 'child_id',
           :class_name => 'NodeGroupNodeGroupAssignment',
           :dependent => :destroy
  # Then establish the relationship with the groups on the other end
  # of those assignments
  has_many :parent_groups, :through => :assignments_as_child
  has_many :child_groups,  :through => :assignments_as_parent

  # for when node_group is tagged as 'service'
  has_many :service_assignments_as_parent,
           :foreign_key => 'parent_id',
           :class_name => 'ServiceServiceAssignment',
           :dependent => :destroy
  has_many :service_assignments_as_child,
           :foreign_key => 'child_id',
           :class_name => 'ServiceServiceAssignment',
           :dependent => :destroy
  has_many :parent_services, :through => :service_assignments_as_child, :class_name => 'Service'
  has_many :child_services,  :through => :service_assignments_as_parent, :class_name => 'Service'
  has_one  :service_profile, :dependent => :destroy, :foreign_key => 'service_id'
  accepts_nested_attributes_for :service_profile, :allow_destroy => true

  # This is used by the edit page in the view
  # http://lists.rubyonrails.org/pipermail/rails/2006-August/059801.html
  def child_group_ids
    child_groups.map(&:id)
  end
  def node_ids
    nodes.map(&:id)
  end

  has_many :node_group_node_assignments, :dependent => :destroy
  has_many :nodes, :through => :node_group_node_assignments
  has_many :node_group_vip_assignments, :dependent => :destroy
  has_many :vips, :through => :node_group_vip_assignments

  belongs_to :lb_profile

  # These constraints are duplicates of constraints imposed at the
  # database layer (see the relevant migration file for details).
  # These are here because they'll catch errors most of the time
  # (they're subject to race conditions, so they won't catch every
  # time), and when they do catch an error they provide a nicer error
  # message back to the user than if the error is caught at the database
  # layer.
  validates_presence_of :name
  validates_uniqueness_of :name
  validates_format_of :owner,
      :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i,
      :message => 'must be a valid email address',
      :allow_nil => true,
      :allow_blank => true

  def self.default_includes
    # The default display index_row columns
    return [:nodes]
  end
      
  def self.default_search_attribute
    'name'
  end
  
  def real_node_group_node_assignments
    node_group_node_assignments.find(:all,:include => {:node =>{}}, :conditions => "node_group_node_assignments.virtual_assignment is null or node_group_node_assignments.virtual_assignment != 1")
  end
  def real_nodes
    real_node_group_node_assignments.collect { |ngna| ngna.node unless ngna.node.nil? }.compact
  end
  def real_nodes_names
    real_node_group_node_assignments.collect { |ngna| ngna.node.name unless ngna.node.nil? }.compact.join(",")
  end
  def virtual_node_group_node_assignments
    node_group_node_assignments.find(:all,:include => {:node_group =>{},:node =>{}}, :conditions => "node_group_node_assignments.virtual_assignment = 1")
  end
  def virtual_nodes
    virtual_node_group_node_assignments.collect { |ngna| ngna.node }
  end
  def virtual_nodes_names
    virtual_node_group_node_assignments.collect { |ngna| ngna.node.name }.join(",")
  end
  
  def real_node_group_vip_assignments
    node_group_vip_assignments.reject { |ngna| ngna.virtual_assignment? }
  end
  def real_vips
    real_node_group_vip_assignments.collect { |ngna| ngna.vip}
  end
  def real_vips_names
    real_node_group_vip_assignments.collect { |ngna| ngna.vip.name }.join(",")
  end
  def virtual_node_group_vip_assignments
    node_group_vip_assignments.select { |ngna| ngna.virtual_assignment? }
  end
  def virtual_vips
    virtual_node_group_vip_assignments.collect { |ngna| ngna.vip}
  end
  def virtual_vips_names
    virtual_node_group_vip_assignments.collect { |ngna| ngna.vip.name }.join(",")
  end

  # This method ensures that the child groups of this node group are the
  # groups represented by the group ids passed to the method
  def set_child_groups(groupids)
    # First ensure that all of the specified assignments exist
    new_assignments = []
    groupids.each do |cgid|
      cg = NodeGroup.find(cgid)
      if !cg.nil? && !child_groups.include?(cg)
        assignment = NodeGroupNodeGroupAssignment.new(:parent_id => id,
                                                      :child_id  => cgid)
        new_assignments << assignment
      end
    end
    
    # Save any new assignments
    node_group_assignment_save_successful = true
    new_assignments.each do |assignment|
      if !assignment.save
        node_group_assignment_save_successful = false
        # Propagate the error from the assignment to ourself
        # so that the user gets some feedback as to the problem
        assignment.errors.each_full { |msg| errors.add(:child_group_ids, msg) }
      end
    end
    
    # Now remove any existing assignments that weren't specified
    assignments_as_parent.each do |assignment|
      if !groupids.include?(assignment.child_id)
        assignment.destroy
      end
    end
    
    node_group_assignment_save_successful
  end
  
  # This method ensures that the nodes of this node group are the
  # nodes represented by the node ids passed to the method
  def set_nodes(nodeids)
    # Have to be careful here to handle existing virtual assignments
    # properly.  If the user has specified a new node and there's an
    # existing virtual assignment we need to convert that into a real
    # assignment.  And when removing nodes that the user didn't
    # specify we don't want to remove virtual assignments.
    
    # First ensure that all of the specified assignments exist
    new_assignments = []
    nodeids.each do |nodeid|
      node = Node.find(nodeid)
      if !node.nil?
        assignment = NodeGroupNodeAssignment.find_by_node_group_id_and_node_id(id, nodeid)
        if assignment.nil?
          assignment = NodeGroupNodeAssignment.new(:node_group_id => id,
                                                   :node_id       => nodeid)
          new_assignments << assignment
        elsif assignment.virtual_assignment?
          assignment.update_attributes(:virtual_assignment => false)
        end
      end
    end
    
    # Save any new assignments
    node_assignment_save_successful = true
    new_assignments.each do |assignment|
      if !assignment.save
        node_assignment_save_successful = false
        # Propagate the error from the assignment to ourself
        # so that the user gets some feedback as to the problem
        assignment.errors.each_full { |msg| errors.add(:node_ids, msg) }
      end
    end
    
    # Now remove any existing assignments that weren't specified
    node_group_node_assignments.each do |assignment|
      if !nodeids.include?(assignment.node_id) && !assignment.virtual_assignment?
        assignment.destroy
      end
    end
    
    node_assignment_save_successful
  end
  
  def all_parent_groups(ng=self,list={},depth=0)
    depth += 1
    ng.parent_groups.each do |parent_group|
      if list[depth].kind_of?(Array)
        list[depth] << parent_group
      else
        list[depth] = [parent_group]
      end
      all_parent_groups(parent_group, list, depth) unless parent_group.parent_groups.empty? 
    end

    # Starting with top level, ensure that value doesn't exist on lower levels
    num_keys = list.keys.last
    list.keys.each do |level|
      count = level 
      while count + 1 <= num_keys
        list[level].each do |parent_ng|
          if list[count + 1].include?(parent_ng)
            raise "Loop detected in node group hierarchy, #{parent_ng.name}\n"
          end
        end
        count += 1
      end
    end
   
    return list.values.flatten
  end
  
  def all_child_groups(ng=self,list={},depth=0)
    depth += 1
    ng.child_groups.each do |child_group|
      if list[depth].kind_of?(Array)
        list[depth] << child_group
      else
        list[depth] = [child_group]
      end
      all_child_groups(child_group, list, depth) unless child_group.child_groups.empty? 
    end

    # Starting with top level, ensure that value doesn't exist on lower levels
    num_keys = list.keys.last
    list.keys.each do |level|
      count = level 
      while count + 1 <= num_keys
        list[level].each do |child_ng|
          if list[count + 1].include?(child_ng)
            raise "Loop detected in node group hierarchy, #{child_ng.name}\n"
          end
        end
        count += 1
      end
    end

    return list.values.flatten
  end
  
  def all_child_groups_except_ngnga(excluded_ngnga, path=[])
    visited = []
    path << self
    
    self.assignments_as_parent.each do |ngnga|
      if ngnga != excluded_ngnga
        # We try to prevent cycles from getting into the node group
        # hierarchy in the first place (see the circular reference
        # validation in NodeGroupNodeGroupAssignment) but a little safety check
        # seems like a good idea, otherwise this method would go into an
        # infinite loop in the face of a cycle.
        if path.include?(ngnga.child_group)
          raise "Loop detected in node group hierarchy, #{self.name} " +
            "has #{ngnga.child_group.name} as a child, check #{ngnga.child_group.name} " +
            " for connections back to #{self.name}"
        end
        visited << ngnga.child_group
        visited.concat(ngnga.child_group.all_child_groups_except_ngnga(excluded_ngnga, path))
      end
    end
    
    visited
  end
  
  def all_child_nodes_except_ngna(excluded_ngna)
    child_nodes = {}
    node_group_node_assignments.each do |ngna|
      if ngna != excluded_ngna
        child_nodes[ngna.node] = true
      end
    end
    all_child_groups.each do |group|
      group.node_group_node_assignments.each do |ngna|
        if ngna != excluded_ngna
          child_nodes[ngna.node] = true
        end
      end
    end
    child_nodes.keys
  end

  def all_child_nodes_except_ngnga(excluded_ngnga)
    child_nodes = {}
    real_nodes.each { |node| child_nodes[node] = true }
    all_child_groups_except_ngnga(excluded_ngnga).each do |group|
      group.nodes.each { |node| child_nodes[node] = true }
    end
    child_nodes.keys
  end

  def is_service?
    self.tag_list.include?('services')
  end

  def to_service
    svc = Service.find(self.id)
    if svc.service_profile.nil?
      return nil
    end
    return svc
  end

  def inherited_users
    account_groups = accepted_roles.collect {|ar| ar.roles_users.collect {|ru| ru.account_group unless ru.account_group.name =~ /\.self$/ }}.flatten.uniq.reject(&:nil?)
    account_groups.collect(&:all_self_groups).flatten.uniq
  end

  def self.preferred_includes
    incls = {}
    incls[:tag] = { :assoc => Tagging.reflect_on_association(:tag),
                             :include => {:taggings=>{:tag=>{}}}}
    incls[:tags] = { :assoc => Tagging.reflect_on_association(:tag),
                             :include => {:taggings=>{:tag=>{}}}}
    return incls
  end

  def recursive_contacts
    data = {}
    owners = []
    contacts = []
    self.owner.split(',').each{|a| owners << a} if self.owner
    self.service_profile.contact.split(',').each{|a| contacts << a} if self.service_profile.contact
    recursive_child_services.each do |child|
      child.owner.split(',').each {|a| owners << a} if child.owner
      child.service_profile.contact.split(',').each {|a| contacts << a} if child.service_profile.contact
    end
    data[:owners] = owners.collect {|a| lookup_email(a)}.uniq.compact
    data[:contacts] = contacts.collect {|a| lookup_email(a)}.uniq.compact
    data[:all] = data[:owners] + data[:contacts]
  end

  def lookup_email(contact)
    return contact if contact =~ /@/
    if SSO_AUTH_SERVER && SSO_PROXY_SERVER
      uri = URI.parse("https://#{SSO_AUTH_SERVER}/users.xml?login=#{contact}")
      http = Net::HTTP::Proxy(SSO_PROXY_SERVER,8080).new(uri.host,uri.port)
      http.use_ssl = true
      sso_xmldata = http.get(uri.request_uri).body
      sso_xmldoc = Hpricot::XML(sso_xmldata)
      email = (sso_xmldoc/:email).first.innerHTML if (sso_xmldoc/:email).first
      email ? (return email) : (return nil)
    else
      return nil
    end
  end

  def recursive_child_services
    recurse_child_services(self)
  end

  def recurse_child_services(ng)
    children = []
    if ng.child_services.size > 0
      ng.child_services.each do |child|
        children << child
        results = recurse_child_services(child)
        results.each{|a| children << a}
      end
    else
      return []
    end
    return children
  end

end
