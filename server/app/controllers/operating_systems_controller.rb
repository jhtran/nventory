class OperatingSystemsController < ApplicationController
  # GET /operating_systems
  # GET /operating_systems.xml
  def index
    includes = process_includes(OperatingSystem, params[:include])
    
    sort = case params['sort']
           when "name" then "operating_systems.name"
           when "name_reverse" then "operating_systems.name DESC"
           end
    
    # if a sort was not defined we'll make one default
    if sort.nil?
      params['sort'] = OperatingSystem.default_search_attribute
      sort = 'operating_systems.' + OperatingSystem.default_search_attribute
    end
    
    # XML doesn't get pagination
    if params[:format] && params[:format] == 'xml'
      @objects = OperatingSystem.find(:all,
                                      :include => includes,
                                      :order => sort)
    else
      @objects = OperatingSystem.paginate(:all,
                                          :include => includes,
                                          :order => sort,
                                          :page => params[:page])
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @objects.to_xml(:include => convert_includes(includes),
                                                   :dasherize => false) }
    end
  end

  # GET /operating_systems/1
  # GET /operating_systems/1.xml
  def show
    includes = process_includes(OperatingSystem, params[:include])
    
    @operating_system = OperatingSystem.find(params[:id],
                                             :include => includes)

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @operating_system.to_xml(:include => convert_includes(includes),
                                                            :dasherize => false) }
    end
  end

  # GET /operating_systems/new
  def new
    @operating_system = OperatingSystem.new
  end

  # GET /operating_systems/1/edit
  def edit
    @operating_system = OperatingSystem.find(params[:id])
  end

  # POST /operating_systems
  # POST /operating_systems.xml
  def create
    @operating_system = OperatingSystem.new(params[:operating_system])

    respond_to do |format|
      if @operating_system.save
        flash[:notice] = 'OperatingSystem was successfully created.'
        format.html { redirect_to operating_system_url(@operating_system) }
        format.xml  { head :created, :location => operating_system_url(@operating_system) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @operating_system.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /operating_systems/1
  # PUT /operating_systems/1.xml
  def update
    @operating_system = OperatingSystem.find(params[:id])

    respond_to do |format|
      if @operating_system.update_attributes(params[:operating_system])
        flash[:notice] = 'OperatingSystem was successfully updated.'
        format.html { redirect_to operating_system_url(@operating_system) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @operating_system.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /operating_systems/1
  # DELETE /operating_systems/1.xml
  def destroy
    @operating_system = OperatingSystem.find(params[:id])
    @operating_system.destroy

    respond_to do |format|
      format.html { redirect_to operating_systems_url }
      format.xml  { head :ok }
    end
  end
  
  # GET /operating_systems/1/version_history
  def version_history
    @operating_system = OperatingSystem.find(params[:id])
    render :action => "version_table", :layout => false
  end
  
  # GET /operating_systems/field_names
  def field_names
    super(OperatingSystem)
  end

  # GET /operating_systems/search
  def search
    @operating_system = OperatingSystem.find(:first)
    render :action => 'search'
  end
  
end
