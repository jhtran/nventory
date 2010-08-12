class DatacentersController < ApplicationController
  # sets the @auth object and @object
  before_filter :get_obj_auth
  before_filter :modelperms

  # GET /datacenters
  # GET /datacenters.xml
  def index
    ## BUILD MASTER HASH WITH ALL SUB-PARAMS ##
    allparams = {}
    allparams[:mainmodel] = Datacenter
    allparams[:webparams] = params
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

  # GET /datacenters/1
  # GET /datacenters/1.xml
  def show
    @datacenter = @object

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @datacenter.to_xml(:include => convert_includes(includes),
                                                      :dasherize => false) }
    end
  end

  # GET /datacenters/new
  def new
    @datacenter = @object
  end

  # GET /datacenters/1/edit
  def edit
    @datacenter = @object
  end

  # POST /datacenters
  # POST /datacenters.xml
  def create
    @datacenter = Datacenter.new(params[:datacenter])

    respond_to do |format|
      if @datacenter.save
        flash[:notice] = 'Datacenter was successfully created.'
        format.html { redirect_to datacenter_url(@datacenter) }
        format.xml  { head :created, :location => datacenter_url(@datacenter) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @datacenter.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /datacenters/1
  # PUT /datacenters/1.xml
  def update
    @datacenter = @object

    respond_to do |format|
      if @datacenter.update_attributes(params[:datacenter])
        flash[:notice] = 'Datacenter was successfully updated.'
        format.html { redirect_to datacenter_url(@datacenter) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @datacenter.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /datacenters/1
  # DELETE /datacenters/1.xml
  def destroy
    @datacenter = @object
    begin
      @datacenter.destroy
    rescue Exception => destroy_error
      respond_to do |format|
        flash[:error] = destroy_error.message
        format.html { redirect_to datacenter_url(@datacenter) and return}
        format.xml  { head :error } # FIXME?
      end
    end
    
    # Success!
    respond_to do |format|
      format.html { redirect_to datacenters_url }
      format.xml  { head :ok }
    end
  end
  
  # GET /datacenters/1/version_history
  def version_history
    @datacenter = Datacenter.find(params[:id])
    render :action => "version_table", :layout => false
  end
  
  # GET /datacenters/1/visualization
  def visualization
    @datacenter = Datacenter.find(params[:id])
  end
  
  # GET /datacenters/field_names
  def field_names
    super(Datacenter)
  end

  # GET /datacenters/search
  def search
    @datacenter = Datacenter.find(:first)
    render :action => 'search'
  end
  
end
