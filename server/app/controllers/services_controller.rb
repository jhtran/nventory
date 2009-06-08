class ServicesController < ApplicationController
  # GET /node_groups
  # GET /node_groups.xml
  def index
    # The default display index_row columns (node_groups model only displays local table name)
    default_includes = []
    special_joins = {}

    ## BUILD MASTER HASH WITH ALL SUB-PARAMS ##
    allparams = {}
    allparams[:mainmodel] = NodeGroup
    allparams[:webparams] = params
    allparams[:default_includes] = default_includes
    allparams[:special_joins] = special_joins

    results = SearchController.new.search(allparams)
    flash[:error] = results[:errors].join('<br />') unless results[:errors].empty?
    includes = results[:includes]
    @objects = results[:search_results]
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @objects.to_xml(:include => convert_includes(includes),
						   :methods => [:virtual_nodes_names, :real_nodes_names],
                                                   :dasherize => false) }
    end
  end

  # GET /node_groups/1
  # GET /node_groups/1.xml
  def show
    includes = process_includes(NodeGroup, params[:include])
    if (params[:withdeleted] == '1')
      @node_group = NodeGroup.find_with_deleted(params[:id], :include => includes)
    else
      @node_group = NodeGroup.find(params[:id], :include => includes)
    end

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
   if (params[:withdeleted] == '1')
      @node_group = NodeGroup.find_with_deleted(params[:id])
    else
      @node_group = NodeGroup.find(params[:id])
    end

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
      logger.debug "service_assignment_save_successful: #{node_group_assignment_save_successful}"
      # Process any node -> node group assignment creations
      node_assignment_save_successful = process_node_assignments()
      logger.debug "node_assignment_save_successful: #{node_assignment_save_successful}"
    end

    respond_to do |format|
      if node_save_successful && node_group_assignment_save_successful && node_assignment_save_successful
        flash[:notice] = 'Service was successfully created.'
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
    @node_group = NodeGroup.find_with_deleted(params[:id])
    if (defined?(params[:node_group_node_group_assignments][:child_groups]) && params[:node_group_node_group_assignments][:child_groups].include?('nil'))
      params[:node_group_node_group_assignments][:child_groups] = []
    end

    # Process any node group -> node group assignment updates
    node_group_assignment_save_successful = process_node_group_assignments()

    # Process any node -> node group assignment updates
    node_assignment_save_successful = process_node_assignments()

    respond_to do |format|
      if node_group_assignment_save_successful && node_assignment_save_successful && @node_group.update_attributes(params[:node_group])
        flash[:notice] = 'Service was successfully updated.'
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
