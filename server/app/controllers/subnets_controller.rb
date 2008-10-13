class SubnetsController < ApplicationController
  # GET /subnets
  # GET /subnets.xml
  def index
    includes = process_includes(Subnet, params[:include])
    
    sort = case params['sort']
           when "network" then "subnets.network"
           when "network_reverse" then "subnets.network DESC"
           end
    
    # if a sort was not defined we'll make one default
    if sort.nil?
      params['sort'] = Subnet.default_search_attribute
      sort = 'subnets.' + Subnet.default_search_attribute
    end
    
    # XML doesn't get pagination
    if params[:format] && params[:format] == 'xml'
      @objects = Subnet.find(:all,
                             :include => includes,
                             :order => sort)
    else
      @objects = Subnet.paginate(:all,
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

  # GET /subnets/1
  # GET /subnets/1.xml
  def show
    includes = process_includes(Subnet, params[:include])
    
    @subnet = Subnet.find(params[:id],
                          :include => includes)

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @subnet.to_xml(:include => convert_includes(includes),
                                                  :dasherize => false) }
    end
  end

  # GET /subnets/new
  def new
    @subnet = Subnet.new
  end

  # GET /subnets/1/edit
  def edit
    @subnet = Subnet.find(params[:id])
  end

  # POST /subnets
  # POST /subnets.xml
  def create
    @subnet = Subnet.new(params[:subnet])

    respond_to do |format|
      if @subnet.save
        flash[:notice] = 'Subnet was successfully created.'
        format.html { redirect_to subnet_url(@subnet) }
        format.xml  { head :created, :location => subnet_url(@subnet) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @subnet.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /subnets/1
  # PUT /subnets/1.xml
  def update
    @subnet = Subnet.find(params[:id])

    respond_to do |format|
      if @subnet.update_attributes(params[:subnet])
        flash[:notice] = 'Subnet was successfully updated.'
        format.html { redirect_to subnet_url(@subnet) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @subnet.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /subnets/1
  # DELETE /subnets/1.xml
  def destroy
    @subnet = Subnet.find(params[:id])
    @subnet.destroy

    respond_to do |format|
      format.html { redirect_to subnets_url }
      format.xml  { head :ok }
    end
  end
  
  # GET /subnets/1/version_history
  def version_history
    @subnet = Subnet.find_with_deleted(params[:id])
    render :action => "version_table", :layout => false
  end
  
  # GET /subnets/field_names
  def field_names
    super(Subnet)
  end

  # GET /subnets/search
  def search
    @subnet = Subnet.find(:first)
    render :action => 'search'
  end
  
end
