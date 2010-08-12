class IpAddressesController < ApplicationController
  # sets the @auth object and @object
  before_filter :get_obj_auth
  before_filter :modelperms

  # GET /ip_addresses
  # GET /ip_addresses.xml
  $address_types = %w( ipv4 ipv6 )
  def index
    special_joins = {}
    ## BUILD MASTER HASH WITH ALL SUB-PARAMS ##
    allparams = {}
    allparams[:mainmodel] = IpAddress
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

  # GET /ip_addresses/1
  # GET /ip_addresses/1.xml
  def show
    @ip_address = @object

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @ip_address.to_xml(:include => convert_includes(includes),
                                                      :dasherize => false) }
    end
  end

  # GET /ip_addresses/new
  def new
    @ip_address = @object
  end

  # GET /ip_addresses/1/edit
  def edit
    @ip_address = @object
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
    @ip_address = @object
    if params[:network_ports]
      portshashes = params[:network_ports]
      process_network_ports(@ip_address,portshashes)
      params.delete(:network_ports)
    end

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

  def process_network_ports(ip, porthashes)
    logger.info "\n\n*********** PROCESSING NETWORK PORTS ***************"
    logger.info "IP: #{ip.address}\n" + porthashes.to_yaml + "\n\n"

    porthashes.each_pair do |key,porthash|
      if porthash["nmap"] == "1"
        nmap = true
        porthash.delete(:nmap)
        ip.nmap_last_scanned_at = DateTime.now
      end
      logger.info "Search for PORT: #{porthash[:number]}/#{porthash[:protocol]}"
      port = NetworkPort.find_or_create_by_number_and_protocol(porthash[:number].to_i,porthash[:protocol])
      ipnpa = IpAddressNetworkPortAssignment.find_or_create_by_ip_address_id_and_network_port_id(ip.id,port.id)
      if ipnpa
        # we want to append to the :app field instead of overwriting unless that appname already is listed
        if ipnpa.apps && ipnpa.apps =~ /\w/
          if ipnpa.apps =~ /\b#{porthash[:apps]}\b/
            ipnpa.apps = ipnpa.apps.gsub(/\s/,'')
          else
            ipnpa.apps = [ipnpa.apps.gsub(/\s/,''), porthash[:apps]].join(',')
          end
        else
          ipnpa.apps = porthash[:apps]
        end
        if nmap
          ipnpa.nmap_first_seen_at = DateTime.now unless ipnpa.nmap_first_seen_at
          ipnpa.nmap_last_seen_at = DateTime.now
        end
        ipnpa.save
      end  # if ipnpa
      logger.info "** NetworkPortIpAddressAssignment RESULT (ID): #{ipnpa.id}"
    end
  end
  private :process_network_ports

  # DELETE /ip_addresses/1
  # DELETE /ip_addresses/1.xml
  def destroy
    @ip_address = @object
    @ip_address.destroy

    respond_to do |format|
      format.html { redirect_to ip_addresses_url }
      format.xml  { head :ok }
    end
  end
  
  # GET /ip_addresses/1/version_history
  def version_history
    @ip_address = IpAddress.find(params[:id])
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
