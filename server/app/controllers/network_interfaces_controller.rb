class NetworkInterfacesController < ApplicationController
  # sets the @auth object and @object
  before_filter :get_obj_auth
  before_filter :modelperms

  # GET /network_interfaces
  # GET /network_interfaces.xml
  def index
    ## BUILD MASTER HASH WITH ALL SUB-PARAMS ##
    allparams = {}
    allparams[:mainmodel] = NetworkInterface
    allparams[:webparams] = params
    results = Search.new(allparams).search

    flash[:error] = results[:errors].join('<br />') unless results[:errors].empty?
    includes = results[:includes]
    results[:requested_includes].each_pair{|k,v| includes[k] = v}
    @objects = results[:search_results]

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @objects.to_xml(:include => convert_includes(includes), :dasherize => false) }
    end
  end

  # GET /network_interfaces/1
  # GET /network_interfaces/1.xml
  def show
    @network_interface = @object

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @network_interface.to_xml(:include => convert_includes(includes), :dasherize => false) }
    end
  end

  # GET /network_interfaces/new
  def new
    @network_interface = @object
  end

  # GET /network_interfaces/1/edit
  def edit
    @network_interface = @object
  end

  # POST /network_interfaces
  # POST /network_interfaces.xml
  def create
    @network_interface = NetworkInterface.new(params[:network_interface])

    # If the user specified some IP address info then handle that
    if params.include?(:ip_addresses)
      # Neat trick from http://www.stephenchu.com/2008/03/paramsfu-3-using-fieldsfor-and-index.html
      if params[:ip_addresses].kind_of?(Hash)
        @network_interface.ip_addresses.build params[:ip_addresses].values
      elsif params[:ip_addresses].kind_of?(Array)
        @network_interface.ip_addresses.build params[:ip_addresses]
      end
    end

    respond_to do |format|
      if @network_interface.save
        flash[:notice] = 'NetworkInterface was successfully created.'
        format.html { redirect_to network_interface_url(@network_interface) }
        format.xml  { head :created, :location => network_interface_url(@network_interface) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @network_interface.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /network_interfaces/1
  # PUT /network_interfaces/1.xml
  def update
    @network_interface = @object

    # If the user specified some IP address info then handle that
    if params.include?(:ip_addresses)
      logger.info "User included IP info, handling it"

      authoritative = false
      iphashes = []
      if params[:ip_addresses].kind_of?(Hash)
        # Pull out the authoritative flag if the user specified it
        if params[:ip_addresses].include?(:authoritative)
          authoritative = params[:ip_addresses][:authoritative]
          params[:ip_addresses].delete(:authoritative)
        end
        iphashes = params[:ip_addresses].values
      elsif params[:ip_addresses].kind_of?(Array)
        iphashes = params[:ip_addresses]
      end
      
      iphashes.each do |iphash|
        logger.info "Search for IP #{iphash[:address]}"
        ip = @network_interface.ip_addresses.find_by_address(iphash[:address])
        if ip.nil?
          logger.info "IP #{ipash[:address]} doesn't exist, creating it" + iphash.to_yaml
          IpAddress.create(iphash)
        else
          logger.info "IP #{ipash[:address]} exists, updating it" + iphash.to_yaml
          ip.update_attributes(iphash)
        end
      end

      # If the client indicated that they were sending us an authoritative
      # set of info for this NIC then remove any IPs stored in the database
      # which the client didn't include in the info it sent
      if authoritative
        ips_from_client = []
        iphashes.each { |iphash| ips_from_client.push(iphash[:address]) }
        @network_interface.ip_addresses.each do |ip|
          if !ips_from_client.include?(ip.address)
            ip.destroy
          end
        end
      end

    end # if params.include?(:ip_addresses)
    
    respond_to do |format|
      if @network_interface.update_attributes(params[:network_interface])
        flash[:notice] = 'NetworkInterface was successfully updated.'
        format.html { redirect_to network_interface_url(@network_interface) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @network_interface.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /network_interfaces/1
  # DELETE /network_interfaces/1.xml
  def destroy
    @network_interface = @object
    @network_interface.destroy

    respond_to do |format|
      format.html { redirect_to network_interfaces_url }
      format.xml  { head :ok }
    end
  end
  
  # GET /network_interfaces/1/version_history
  def version_history
    @network_interface = NetworkInterface.find(params[:id])
    render :action => "version_table", :layout => false
  end
  
  # GET /network_interfaces/field_names
  def field_names
    super(NetworkInterface)
  end

  # GET /network_interfaces/search
  def search
    @network_interface = NetworkInterface.find(:first)
    render :action => 'search'
  end
  
end
