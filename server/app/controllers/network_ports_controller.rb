class NetworkPortsController < ApplicationController
  # sets the @auth object and @object
  before_filter :get_obj_auth
  before_filter :modelperms

  $network_port_types = %w(nfs ext3 ext2 ext4 smb)
  # GET /network_ports
  # GET /network_ports.xml
  def index
    special_joins = {}

    ## BUILD MASTER HASH WITH ALL SUB-PARAMS ##
    allparams = {}
    allparams[:mainmodel] = NetworkPort
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

  # GET /network_ports/1
  # GET /network_ports/1.xml
  def show
    @network_port = @object

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @network_port.to_xml(:include => convert_includes(includes),
                                                :dasherize => false) }
    end
  end

  # GET /network_ports/new
  def new
    @network_port = @object
    respond_to do |format|
      format.html # show.html.erb
      format.js  { render :action => "inline_new", :layout => false }
    end
  end

  # GET /network_ports/1/edit
  def edit
    @network_port = @object
  end

  # POST /network_ports
  # POST /network_ports.xml
  def create
    @network_port = NetworkPort.new(params[:network_port])
    respond_to do |format|
      if @network_port.save
        flash[:notice] = 'NetworkPort was successfully created.'
        format.html { redirect_to network_port_url(@network_port) }
        format.xml  { head :created, :location => network_port_url(@network_port) }
      else
        format.html { render :action => "new" }
        format.js   { render(:update) { |page| page.alert(@network_port.errors.full_messages) } }
        format.xml  { render :xml => @network_port.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /network_ports/1
  # PUT /network_ports/1.xml
  def update
    @network_port = @object

    respond_to do |format|
      if @network_port.update_attributes(params[:network_port])
        flash[:notice] = 'NetworkPort was successfully updated.'
        format.html { redirect_to network_port_url(@network_port) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @network_port.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /network_ports/1
  # DELETE /network_ports/1.xml
  def destroy
    @network_port = @object
    begin
      @network_port.destroy
    rescue Exception => destroy_error
      respond_to do |format|
        flash[:error] = destroy_error.message
        format.html { redirect_to network_port_url(@network_port) and return}
        format.xml  { head :error } # FIXME?
      end
    end
    
    # Success!
    respond_to do |format|
      format.html { redirect_to network_ports_url }
      format.xml  { head :ok }
    end
  end
  
  # GET /network_ports/1/version_history
  def version_history
    @network_port = NetworkPort.find(params[:id])
    render :action => "version_table", :layout => false
  end
  
  # GET /network_ports/1/visualization
  def visualization
    @network_port = NetworkPort.find(params[:id])
  end
  
  # GET /network_ports/field_numbers
  def field_numbers
    super(NetworkPort)
  end

  # GET /network_ports/search
  def search
    @network_port = NetworkPort.find(:first)
    render :action => 'search'
  end
  
end
