class IpAddressesController < ApplicationController
  # GET /ip_addresses
  # GET /ip_addresses.xml
  def index
    includes = {}

    sort = case params['sort']
           when "address"                   then "ip_addresses.address"
           when "address_reverse"           then "ip_addresses.address DESC"
           when "network_interface"         then includes[:network_interface] = true; "network_interface.name"
           when "network_interface_reverse" then includes[:network_interface] = true; "network_interface.name DESC"
           when "node"                      then includes[[:network_interface => :node]] = true; "node.name"
           when "node_reverse"              then includes[[:network_interface => :node]] = true; "node.name DESC"
           end
    
    # if a sort was not defined we'll make one default
    if sort.nil?
      params['sort'] = IpAddress.default_search_attribute
      sort = 'ip_addresses.' + IpAddress.default_search_attribute
    end

    # The index page includes some data from associations.  If we don't
    # include those associations then N SQL calls result as that data is
    # looked up row by row.
    if !params[:format] || params[:format] == 'html'
      includes[[:network_interface => :node]] = true
    end
    
    # The data we render to XML includes some data from associations.
    # If we don't include those associations then N SQL calls result
    # as that data is looked up row by row.
    if params[:format] && params[:format] == 'xml'
      includes[[:network_interface => :node]] = true
    end
    
    logger.info "includes" + includes.keys.to_yaml

    # XML doesn't get pagination
    if params[:format] && params[:format] == 'xml'
      @objects = IpAddress.find(:all,
                                :include => includes.keys,
                                :order => sort)
    else
      @objects = IpAddress.paginate(:all,
                                    :include => includes.keys,
                                    :order => sort,
                                    :page => params[:page])
    end
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @objects.to_xml(
                                :include => {
                                  :network_interface => { :include => :node }
                                  },
                                :dasherize => false) }
    end
  end

  # GET /ip_addresses/1
  # GET /ip_addresses/1.xml
  def show
    includes = {}
    # The data we render to XML includes some data from associations.
    # If we don't include those associations then N SQL calls result
    # as that data is looked up row by row.
    if params[:format] && params[:format] == 'xml'
      includes[[:network_interface => :node]] = true
    end
    
    @ip_address = IpAddress.find(params[:id],
                                 :include => includes.keys)

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @ip_address.to_xml(
                                :include => {
                                  :network_interface => { :include => :node }
                                  },
                                :dasherize => false) }
    end
  end

  # GET /ip_addresses/new
  def new
    @ip_address = IpAddress.new
  end

  # GET /ip_addresses/1/edit
  def edit
    @ip_address = IpAddress.find(params[:id])
  end

  # POST /ip_addresses
  # POST /ip_addresses.xml
  def create
    @ip_address = IpAddress.new(params[:ip_address])

    respond_to do |format|
      if @ip_address.save
        flash[:notice] = 'IpAddress was successfully created.'
        format.html { redirect_to ip_address_url(@ip_address) }
        format.xml  { head :created, :location => ip_address_url(@ip_address) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @ip_address.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /ip_addresses/1
  # PUT /ip_addresses/1.xml
  def update
    @ip_address = IpAddress.find(params[:id])

    respond_to do |format|
      if @ip_address.update_attributes(params[:ip_address])
        flash[:notice] = 'IpAddress was successfully updated.'
        format.html { redirect_to ip_address_url(@ip_address) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @ip_address.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /ip_addresses/1
  # DELETE /ip_addresses/1.xml
  def destroy
    @ip_address = IpAddress.find(params[:id])
    @ip_address.destroy

    respond_to do |format|
      format.html { redirect_to ip_addresses_url }
      format.xml  { head :ok }
    end
  end
  
  # GET /ip_addresses/1/version_history
  def version_history
    @ip_address = IpAddress.find_with_deleted(params[:id])
    render :action => "version_table", :layout => false
  end
  
  # GET /ip_addresses/field_names
  def field_names
    super(IpAddress)
  end

  # GET /ip_addresses/search
  def search
    @ip_address = IpAddress.find(:first)
    render :action => 'search'
  end
  
end
