class VipsController < ApplicationController
  # sets the @auth object and @object
  before_filter :get_obj_auth
  before_filter :modelperms

  # GET /vips
  # GET /vips.xml
  $protocols = %w[ tcp udp both ]
  def index
    special_joins = {}

    ## BUILD MASTER HASH WITH ALL SUB-PARAMS ##
    allparams = {}
    allparams[:mainmodel] = Vip
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

  # GET /vips/1
  # GET /vips/1.xml
  def show
    @vip = @object

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @vip.to_xml(:include => convert_includes(includes),
                                               :dasherize => false) }
    end
  end

  # GET /vips/new
  def new
    @vip = @object
    @vip.build_ip_address
  end

  # GET /vips/1/edit
  def edit
    @vip = @object
  end

  # POST /vips
  # POST /vips.xml
  def create
    @vip = Vip.new(params[:vip])
    # resuse ip_address record if one already exists with same address and type
    ip = IpAddress.find_or_create_by_address_and_address_type(params[:vip][:ip_address_attributes])
    @vip.ip_address = ip
    respond_to do |format|
      if @vip.save
        flash[:notice] = 'vip was successfully created.'
        format.html { redirect_to vip_url(@vip) }
        format.xml  { head :created, :location => vip_url(@vip) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @vip.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /vips/1
  # PUT /vips/1.xml
  def update
    @vip = @object
    # resuse ip_address record if one already exists with same address and type
    ip = IpAddress.find_or_create_by_address_and_address_type(params[:vip][:ip_address_attributes])
    params[:vip][:ip_address_attributes][:id] = ip.id
    respond_to do |format|
      if @vip.update_attributes(params[:vip])
        flash[:notice] = 'vip was successfully updated.'
        format.html { redirect_to vip_url(@vip) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @vip.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /vips/1
  # DELETE /vips/1.xml
  def destroy
    @vip = @object
    @vip.destroy

    respond_to do |format|
      format.html { redirect_to vips_url }
      format.xml  { head :ok }
    end
  end
  
  # GET /vips/1/version_history
  def version_history
    @vip = Vip.find(params[:id])
    render :action => "version_table", :layout => false
  end
  
  # GET /vips/field_names
  def field_names
    super(Vip)
  end

  # GET /vips/search
  def search
    @vip = Vip.find(:first)
    render :action => 'search'
  end
  
end
