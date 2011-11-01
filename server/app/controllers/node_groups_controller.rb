class NodeGroupsController < ApplicationController
  # sets the @auth object and @object
  before_filter :get_obj_auth
  before_filter :modelperms

  # GET /node_groups
  # GET /node_groups.xml
  def index
    special_joins = {}

    ## BUILD MASTER HASH WITH ALL SUB-PARAMS ##
    allparams = {}
    allparams[:mainmodel] = NodeGroup
    allparams[:webparams] = params
    allparams[:special_joins] = special_joins

    results = Search.new(allparams).search
    flash[:error] = results[:errors].join('<br />') unless results[:errors].empty?
    includes = results[:includes]
    results[:requested_includes].each_pair{|k,v| includes[k] = v}
    @objects = results[:search_results]
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { 
        # PS-704 
        if params[:nodefmeth]
          render :xml => @objects.to_xml(:include => convert_includes(includes), :dasherize => false)
        else
          render :xml => @objects.to_xml(:include => convert_includes(includes),
	            :methods => [:virtual_nodes_names, :real_nodes_names], :dasherize => false)
        end
      }
    end
  end

  # GET /node_groups/1
  # GET /node_groups/1.xml
  def show
    @node_group = @object
    if @node_group.is_service? 
      convert_to_service(@node_group) unless @node_group.service_profile
      @app_locs = {}
      @app_locs['Development'] = return_url_or_node(@node_group.service_profile.dev_url)
      @app_locs['QA'] = return_url_or_node(@node_group.service_profile.qa_url)
      @app_locs['Production'] = return_url_or_node(@node_group.service_profile.prod_url)
      @app_locs['Staging'] = return_url_or_node(@node_group.service_profile.stg_url)
      @app_locs['Code Repository'] = return_url_or_node(@node_group.service_profile.repo_url)
    end
    percent_cpu_obj = UtilizationMetricName.find_by_name('percent_cpu')
    percent_cpus = UtilizationMetricsByNodeGroup.find(:all,:include => {:node_group => {},:utilization_metric_name=> {}},
                                        :conditions => ["node_groups.id = ? and utilization_metric_names.id = ? and assigned_at like ?", @node_group.id, percent_cpu_obj.id, "%#{1.days.ago.strftime("%Y-%m-%d")}%"])
    unless percent_cpus.empty?
      @percent_cpu_today = percent_cpus.collect{|each| each.value.to_i}.sum.to_i / percent_cpus.size.to_i
    else
      @percent_cpu_today = "No data"
    end
    @percent_cpu_node_count = percent_cpus.last.node_count unless percent_cpus.empty?

    respond_to do |format|
      format.html { @cpu_percent_chart = open_flash_chart_object(500,300, url_for( :action => 'show', :graph => 'cpu_percent_chart', :format => :json )) }
      format.xml  { render :xml => @node_group.to_xml(:include => convert_includes(includes),
                                                      :dasherize => false) }
      format.json {
        case params[:graph]
          when 'cpu_percent_chart'
            chart = cpu_percent_chart_method
            render :text => chart.to_s
        end
      } # format.json
    end
  end

  # GET /node_groups/new
  def new
    @node_group = @object
  end

  # GET /node_groups/1/edit
  def edit
    @node_group = @object
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
    @node_group = @object
    if (defined?(params[:node_group_node_group_assignments][:child_groups]) && params[:node_group_node_group_assignments][:child_groups].include?('nil'))
      params[:node_group_node_group_assignments][:child_groups] = []
    end
    if (defined?(params[:node_group_node_assignments][:nodes]) && params[:node_group_node_assignments][:nodes].include?('nil'))
      params[:node_group_node_assignments][:nodes] = []
    end

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
    @node_group = @object
    @node_group.destroy

    respond_to do |format|
      format.html { redirect_to node_groups_url }
      format.xml  { head :ok }
    end
  end

  def add_tag
    return unless filter_perms(@auth,Tag,['creator'])
    @node_group = NodeGroup.find(params[:id])
    return unless filter_perms(@auth,@node_group,['updater'])
    @node_group.tag_list << params[:tag].to_s
    respond_to do |format|
      format.js {
        if @node_group.save
          convert_to_service(@node_group) if @node_group.is_service? and !@node_group.service_profile
          render(:update) { |page|
            page.replace_html 'tag_list', :partial => 'node_groups/tag_list', :locals => { :tags => @node_group.tags }
            page.hide 'add_tag'
            page.hide 'new_tag'
            page.show 'add_tag_link'
          }
        else
          render(:update) { |page| page.alert(@node_group.errors.full_messages) }
        end
      }
    end
  end

  def add_graffiti
    return unless filter_perms(@auth,Graffiti,['creator'])
    @node_group = NodeGroup.find(params[:id])
    return unless filter_perms(@auth,@node_group,['updater'])
   
    @node_group.graffiti_map[params[:name].to_s] = params[:value].to_s
    respond_to do |format|
      format.js {
        if @node_group.save
          render(:update) { |page|
            page.replace_html 'graffiti_list', :partial => 'node_groups/graffiti_list', :locals => { :graffitis => @node_group.graffitis }
            page.hide 'new_graffiti'
            page.show 'add_graffiti_link'
          }
        else
          render(:update) { |page| page.alert(@node_group.errors.full_messages) }
        end
      }
    end
  end
  
  # GET /node_groups/1/version_history
  def version_history
    @node_group = NodeGroup.find(params[:id])
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

  def cpu_percent_chart_method
    @node_group = NodeGroup.find(params[:id])
    data = {}
    data[:days] = []
    data[:values] = []

    # Create datapoints for the past 12 months and keep them in array so that their order is retained
    counter = 10
    while counter > 0 
      day = counter
      values = UtilizationMetricsByNodeGroup.find(
          :all, :include => {:utilization_metric_name => {}, :node_group => {}},
          :conditions => ["node_groups.id = ? and assigned_at like ? and utilization_metric_names.name = ?", @node_group.id, "%#{day.days.ago.strftime("%Y-%m-%d")}%", 'percent_cpu'])
      # each day should only have 1 value, if not then create an average
      if values.size == 0 
        counter -=1
        next
      elsif values.size == 1
        value = values.first.value
      else
        value = values.collect{|a| a.value.to_i }.sum / values.size
      end 
      data[:days] << day.days.ago.strftime("%m/%d")
      data[:values] << value.to_i
      counter -= 1
    end 
    PP.pp data
    # Create Graph
    title = Title.new("#{@node_group.name.titleize} CPU% Utilization")
    title.set_style('{font-size: 20px; color: #778877}')
    line = Line.new
    line.text = "%" 
    line.set_values(data[:values])
    y = YAxis.new
    y.set_range(0,100,10)
    x = XAxis.new
    x.set_labels(data[:days])

    chart = OpenFlashChart.new
    chart.set_title(title)
    chart.add_element(line)
    chart.x_axis = x 
    chart.y_axis = y 

    return chart
  end 

  def graph_node_groups
    @node_group = NodeGroup.find(params[:id])
    @graphobjs = {}
    @graph = GraphViz::new( "G", "output" => "png" )
    @dots = {}
    @graphobjs[@node_group.name.gsub(/-/,'')] = @graph.add_node(@node_group.name.gsub(/-/,''), :label => "#{@node_group.name}", :shape => 'rectangle', :color => "yellow", :style => "filled")
    # walk the node_group's parents node_group tree
    dot_parent_groups(@node_group)
    # walk the node_group's children node_group tree 
    dot_child_groups(@node_group)

    ## Write the function to add all the dot points from the hash
    @dots.each_pair do |parent,children|
      children.uniq.each do |child|
        @graph.add_edge( @graphobjs[parent],@graphobjs[child] )
      end
    end
    image_type = MyConfig.visualization.images.mtype
    image_dir = File.join("public", MyConfig.visualization.images.dir)
    @graph.output( :output => image_type,
                   :file => "#{image_dir}/#{@node_group.name}_node_grouptree.#{image_type}" )
    respond_to do |format|
      format.html # graph_node_groups.html.erb
    end
  end

  def dot_child_groups(ng)
    ng.child_groups.each do |child_node_group|
      @graphobjs[child_node_group.name.gsub(/[-.]/,'')] = @graph.add_node(child_node_group.name.gsub(/[-.]/,''), :label => "#{child_node_group.name}", :shape => 'rectangle')
      @dots[ng.name.gsub(/[-.]/,'')] = [] unless @dots[ng.name.gsub(/[-.]/,'')]
      @dots[ng.name.gsub(/[-.]/,'')] << child_node_group.name.gsub(/[-.]/,'')
      unless child_node_group.child_groups.empty?
        dot_child_groups(child_node_group)
      end
    end
  end
  private :dot_child_groups

  def dot_parent_groups(ng)
    ng.parent_groups.each do |parent_node_group|
      @graphobjs[parent_node_group.name.gsub(/[-.]/,'')] = @graph.add_node(parent_node_group.name.gsub(/[-.]/,''), :label => "#{parent_node_group.name}", :shape => 'rectangle')
      @dots[parent_node_group.name.gsub(/[-.]/,'')] = [] unless @dots[parent_node_group.name.gsub(/[-.]/,'')]
      @dots[parent_node_group.name.gsub(/[-.]/,'')] << ng.name.gsub(/[-.]/,'')
      unless parent_node_group.parent_groups.empty?
        dot_parent_groups(parent_node_group)
      end
    end
  end
  private :dot_parent_groups

  def convert_to_service(node_group)
    if node_group.is_service?
      node_group.service_profile_attributes = {}
      node_group.save
    end
  end

  def get_deps
    if params[:id] && params[:partial]
      @node_group = NodeGroup.find(params[:id])
      render :partial => params[:partial], :locals => { :node_group => @node_group, :virtuals_through => @virtuals_through } 
    else
      render :text => ''
    end
  end

  def get_svc_deps
    if params[:id] && params[:partial]
      @node_group = NodeGroup.find(params[:id])
      render :partial => params[:partial], :locals => { :service => @node_group } 
    else
      render :text => ''
    end
  end

  def return_url_or_node(env_url=nil)
    return nil if env_url.nil?
    return env_url if env_url =~ /^http.:\/\//i
    result = Node.find_by_name(env_url)
    result ? (return result) : (return env_url)
  end
  private :return_url_or_node

end
