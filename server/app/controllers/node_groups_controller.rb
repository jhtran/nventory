class NodeGroupsController < ApplicationController
  # GET /node_groups
  # GET /node_groups.xml
  def index
    includes = process_includes(NodeGroup, params[:include])
    
    sort = case params['sort']
           when "name" then "node_groups.name"
           when "name_reverse" then "node_groups.name DESC"
           end
    
    # if a sort was not defined we'll make one default
    if sort.nil?
      params['sort'] = NodeGroup.default_search_attribute
      sort = 'node_groups.' + NodeGroup.default_search_attribute
    end
    
    # This implements a very limited subset of the search functionality
    # supported by the nodes controller.  We should abstract the nodes
    # search functionality and support it in all controllers.  (Most of
    # the other controllers don't support searching at all, they always
    # return all entries.)

    if params[:exact_name]
      # XML doesn't get pagination
      if params[:format] && params[:format] == 'xml'
        @objects = NodeGroup.find(:all,
                                  :conditions => { :name => params[:exact_name] },
                                  :order => sort)
      else
        @objects = NodeGroup.paginate(:all,
                                      :conditions => { :name => params[:exact_name] },
                                      :order => sort,
                                      :page => params[:page])
      end
    else
      # XML doesn't get pagination
      if params[:format] && params[:format] == 'xml'
        @objects = NodeGroup.find(:all,
                                  :include => includes,
                                  :order => sort)
      else
        @objects = NodeGroup.paginate(:all,
                                      :include => includes,
                                      :order => sort,
                                      :page => params[:page])
      end
    end
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @objects.to_xml(:include => convert_includes(includes),
                                                   :dasherize => false) }
    end
  end

  # GET /node_groups/1
  # GET /node_groups/1.xml
  def show
    includes = process_includes(NodeGroup, params[:include])
    
    @node_group = NodeGroup.find(params[:id],
                                 :include => includes)

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @node_group.to_xml(:include => convert_includes(includes),
                                                      :dasherize => false) }
    end
  end

  # GET /node_groups/new
  def new
    @node_group = NodeGroup.new
  end

  # GET /node_groups/1/edit
  def edit
    @node_group = NodeGroup.find(params[:id])
  end

  # POST /node_groups
  # POST /node_groups.xml
  def create
    @node_group = NodeGroup.new(params[:node_group])
    
    node_save_successful = @node_group.save
    logger.debug "node_save_successful: #{node_save_successful}"
    
    if node_save_successful
      # Process any node group -> node group assignment creations
      node_group_assignment_save_successful = process_node_group_assignments()
      logger.debug "node_group_assignment_save_successful: #{node_group_assignment_save_successful}"
      # Process any node -> node group assignment creations
      node_assignment_save_successful = process_node_assignments()
      logger.debug "node_assignment_save_successful: #{node_assignment_save_successful}"
    end

    respond_to do |format|
      if node_save_successful && node_group_assignment_save_successful && node_assignment_save_successful
        flash[:notice] = 'Node group was successfully created.'
        format.html { redirect_to node_group_url(@node_group) }
        format.xml  { head :created, :location => node_group_url(@node_group) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @node_group.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /node_groups/1
  # PUT /node_groups/1.xml
  def update
    @node_group = NodeGroup.find(params[:id])

    # Process any node group -> node group assignment updates
    node_group_assignment_save_successful = process_node_group_assignments()
    # Process any node -> node group assignment updates
    node_assignment_save_successful = process_node_assignments()

    respond_to do |format|
      if node_group_assignment_save_successful && node_assignment_save_successful && @node_group.update_attributes(params[:node_group])
        flash[:notice] = 'Node group was successfully updated.'
        format.html { redirect_to node_group_url(@node_group) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @node_group.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /node_groups/1
  # DELETE /node_groups/1.xml
  def destroy
    @node_group = NodeGroup.find(params[:id])
    @node_group.destroy

    respond_to do |format|
      format.html { redirect_to node_groups_url }
      format.xml  { head :ok }
    end
  end
  
  # GET /node_groups/1/version_history
  def version_history
    @node_group = NodeGroup.find_with_deleted(params[:id])
    render :action => "version_table", :layout => false
  end
  
  # GET /node_groups/field_names
  def field_names
    super(NodeGroup)
  end

  # GET /node_groups/search
  def search
    @node_group = NodeGroup.find(:first)
    render :action => 'search'
  end
  
  def process_node_group_assignments
    r = true
    if params.include?(:node_group_node_group_assignments)
      if params[:node_group_node_group_assignments].include?(:child_groups)
        groupids = params[:node_group_node_group_assignments][:child_groups].collect { |g| g.to_i }
        r = @node_group.set_child_groups(groupids)
      end
    end
    r
  end
  private :process_node_group_assignments

  def process_node_assignments
    r = true
    if params.include?(:node_group_node_assignments)
      if params[:node_group_node_assignments].include?(:nodes)
        nodeids = params[:node_group_node_assignments][:nodes].collect { |n| n.to_i }
        r = @node_group.set_nodes(nodeids)
      end
    end
    r
  end
  private :process_node_assignments

end
