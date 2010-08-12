class SubnetsController < ApplicationController
  # sets the @auth object and @object
  before_filter :get_obj_auth
  before_filter :modelperms

  # GET /subnets
  # GET /subnets.xml
  def index
    ## BUILD MASTER HASH WITH ALL SUB-PARAMS ##
    allparams = {}
    allparams[:mainmodel] = Subnet
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

  # GET /subnets/1
  # GET /subnets/1.xml
  def show
    @subnet = @object

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @subnet.to_xml(:include => convert_includes(includes),
                                                  :dasherize => false) }
    end
  end

  # GET /subnets/new
  def new
    @subnet = @object
  end

  # GET /subnets/1/edit
  def edit
    @subnet = @object
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
    @subnet = @object

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
    @subnet = @object
    @subnet.destroy

    respond_to do |format|
      format.html { redirect_to subnets_url }
      format.xml  { head :ok }
    end
  end
  
  # GET /subnets/1/version_history
  def version_history
    @subnet = Subnet.find(params[:id])
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
