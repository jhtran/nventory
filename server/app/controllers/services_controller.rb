class ServicesController < ApplicationController
  # sets the @auth object and @object
  before_filter :get_obj_auth
  before_filter :modelperms

  # GET /services
  # GET /services.xml
  def index
    special_joins = {}

    ## BUILD MASTER HASH WITH ALL SUB-PARAMS ##
    allparams = {}
    allparams[:mainmodel] = Service
    params['sort'] = "node_group" if ( params['sort'].nil? || params['sort'] == "name" )
    params['sort'] = "node_group_reverse" if ( params['sort'].nil? || params['sort'] == "name_reverse" )
    allparams[:webparams] = params
    allparams[:special_joins] = special_joins

    results = Search.new(allparams).search
    flash[:error] = results[:errors].join('<br />') unless results[:errors].empty?
    includes = results[:includes]
    results[:requested_includes].each_pair{|k,v| includes[k] = v}
    @objects = results[:search_results]
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @objects.to_xml(:include => convert_includes(includes),
                                                   :dasherize => false) }
    end
  end

  # GET /services/1
  # GET /services/1.xml
  def show
    @service = @object
    if @service.service_profile
      @app_locs = {}
      @app_locs['Development'] = return_url_or_node(@service.service_profile.dev_url)
      @app_locs['QA'] = return_url_or_node(@service.service_profile.qa_url)
      @app_locs['Production'] = return_url_or_node(@service.service_profile.prod_url)
      @app_locs['Staging'] = return_url_or_node(@service.service_profile.stg_url)
      @app_locs['Code Repository'] = return_url_or_node(@service.service_profile.repo_url)
    end

    respond_to do |format|
      if @service.service_profile
        format.html # show.html.erb
        format.xml  { render :xml => @service.to_xml(:include => convert_includes(includes),
                                                        :dasherize => false) }
      else
        format.html { redirect_to node_group_url(@service) }
      end
    end
  end

  def return_url_or_node(env_url=nil)

    return nil if env_url.nil?
    return env_url if env_url =~ /^http.:\/\//i
    result = Node.find_by_name(env_url)
    result ? (return result) : (return env_url)
  end
  private :return_url_or_node

  # GET /services/new
  def new
    @service = @object
    @service.build_service_profile
  end

  # GET /services/1/edit
  def edit
    @service = @object
    redirect_to edit_node_group_url(@service) unless @service.service_profile
  end

  # POST /services
  # POST /services.xml
  def create
    @service = Service.new(params[:service])
    
    service_save_successful = @service.save
    logger.debug "service_save_successful: #{service_save_successful}"
    
    if service_save_successful
      # Process any service -> service assignment creations
      service_assignment_save_successful = process_service_assignments()
      logger.debug "service_assignment_save_successful: #{service_assignment_save_successful}"
    end

    respond_to do |format|
      if service_save_successful && service_assignment_save_successful
        flash[:notice] = 'Service was successfully created.'
        format.html { redirect_to service_url(@service) }
        format.xml  { head :created, :location => service_url(@service) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @service.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /services/1
  # PUT /services/1.xml
  def update
    @service = @object
    if (defined?(params[:service_service_assignments][:child_services]) && params[:service_service_assignments][:child_services].include?('nil'))
      params[:service_service_assignments][:child_services] = []
    end

    # Process any service -> service assignment updates
    service_assignment_save_successful = process_service_assignments()

    respond_to do |format|
      if service_assignment_save_successful && @service.update_attributes(params[:service])
        flash[:notice] = 'Service was successfully updated.'
        format.html { redirect_to service_url(@service) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @service.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /services/1
  # DELETE /services/1.xml
  def destroy
    service_profile = @object.service_profile
    service_profile.destroy

    respond_to do |format|
      format.html { redirect_to node_group_path(params[:id]) }
      format.xml  { head :ok }
    end
  end
  
  # GET /services/1/version_history
  def version_history
    @service = Service.find(params[:id])
    render :action => "version_table", :layout => false
  end
  
  # GET /services/field_names
  def field_names
    super(Service)
  end

  # GET /services/search
  def search
    @service = Service.find(:first)
    render :action => 'search'
  end
  
  def process_service_assignments
    r = true
    if params.include?(:service_service_assignments)
      if params[:service_service_assignments].include?(:child_services)
        serviceids = params[:service_service_assignments][:child_services].collect { |g| g.to_i }
        r = @service.set_child_services(serviceids)
      end
    end
    r
  end
  private :process_service_assignments

  def graph_services
    @service = Service.find(params[:id])
    @graphobjs = {}
    @graph = GraphViz::new( "G", "output" => "png" )
    @dots = {}
    @graphobjs[@service.name.gsub(/-/,'')] = @graph.add_node(@service.name.gsub(/-/,''), :label => "#{@service.name}", :shape => 'rectangle', :color => "yellow", :style => "filled")
    # walk the service's parents service tree
    dot_parent_services(@service)
    # walk the service's children service tree 
    dot_child_services(@service)

    ## Write the function to add all the dot points from the hash
    @dots.each_pair do |parent,children|
      children.uniq.each do |child|
        @graph.add_edge( @graphobjs[parent],@graphobjs[child] )
      end
    end
    @graph.output( :output => 'gif',:file => "public/images/#{@service.name}_servicetree.gif" )
    respond_to do |format|
      format.html # graph_services.html.erb
    end
  end

  def dot_child_services(ng)
    ng.child_services.each do |child_service|
      @graphobjs[child_service.name.gsub(/[-.]/,'')] = @graph.add_node(child_service.name.gsub(/[-.]/,''), :label => "#{child_service.name}", :shape => 'rectangle')
      @dots[ng.name.gsub(/[-.]/,'')] = [] unless @dots[ng.name.gsub(/[-.]/,'')]
      @dots[ng.name.gsub(/[-.]/,'')] << child_service.name.gsub(/[-.]/,'')
      unless child_service.child_services.empty?
        dot_child_services(child_service)
      end
    end
  end
  private :dot_child_services

  def dot_parent_services(ng)
    ng.parent_services.each do |parent_service|
      @graphobjs[parent_service.name.gsub(/[-.]/,'')] = @graph.add_node(parent_service.name.gsub(/[-.]/,''), :label => "#{parent_service.name}", :shape => 'rectangle')
      @dots[parent_service.name.gsub(/[-.]/,'')] = [] unless @dots[parent_service.name.gsub(/[-.]/,'')]
      @dots[parent_service.name.gsub(/[-.]/,'')] << ng.name.gsub(/[-.]/,'')
      unless parent_service.parent_services.empty?
        dot_parent_services(parent_service)
      end
    end
  end
  private :dot_parent_services

end
