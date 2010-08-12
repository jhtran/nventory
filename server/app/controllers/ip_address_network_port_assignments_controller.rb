class IpAddressNetworkPortAssignmentsController < ApplicationController
  # sets the @auth object and @object
  before_filter :get_obj_auth
  before_filter :modelperms

  # GET /ip_address_network_port_assignments
  # GET /ip_address_network_port_assignments.xml
  def index
    ## BUILD MASTER HASH WITH ALL SUB-PARAMS ##
    allparams = {}
    allparams[:mainmodel] = IpAddressNetworkPortAssignment
    allparams[:webparams] = params
    results = Search.new(allparams).search

    flash[:error] = results[:errors].join('<br />') unless results[:errors].empty?
    includes = results[:includes]
    results[:requested_includes].each_pair{|k,v| includes[k] = v}
    @objects = results[:search_results]

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @objects.to_xml(:dasherize => false) }
    end
  end

  # GET /ip_address_network_port_assignments/1
  # GET /ip_address_network_port_assignments/1.xml
  def show
    @ip_address_network_port_assignment = @object

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @ip_address_network_port_assignment.to_xml(:dasherize => false) }
    end
  end

  # GET /ip_address_network_port_assignments/new
  def new
    @ip_address_network_port_assignment = @object
  end

  # GET /ip_address_network_port_assignments/1/edit
  def edit
    @ip_address_network_port_assignment = @object
  end

  # POST /ip_address_network_port_assignments
  # POST /ip_address_network_port_assignments.xml
  def create
    @ip_address_network_port_assignment = IpAddressNetworkPortAssignment.new(params[:ip_address_network_port_assignment])
    ip_address = IpAddress.find(params[:ip_address_network_port_assignment][:ip_address_id])
    return unless filter_perms(@auth,ip_address,['updater'])
    network_port = NetworkPort.find(params[:ip_address_network_port_assignment][:network_port_id])
    return unless filter_perms(@auth,network_port,['updater'])

    respond_to do |format|
      if @ip_address_network_port_assignment.save
        format.html {
          flash[:notice] = 'IpAddressNetworkPortAssignment was successfully created.'
          redirect_to ip_address_network_port_assignment_url(@ip_address_network_port_assignment)
        }
        format.xml  { head :created, :location => ip_address_network_port_assignment_url(@ip_address_network_port_assignment) }
      else
        format.html { render :action => "new" }
        format.js   { render(:update) { |page| page.alert(@ip_address_network_port_assignment.errors.full_messages) } }
        format.xml  { render :xml => @ip_address_network_port_assignment.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /ip_address_network_port_assignments/1
  # PUT /ip_address_network_port_assignments/1.xml
  def update
    @ip_address_network_port_assignment = @object
    ip_address = ip_address_network_port_assignment.ip_address
    return unless filter_perms(@auth,ip_address,['updater'])
    network_port = ip_address_network_port_assignment.network_port
    return unless filter_perms(@auth,network_port,['updater'])

    respond_to do |format|
      if @ip_address_network_port_assignment.update_attributes(params[:ip_address_network_port_assignment])
        flash[:notice] = 'IpAddressNetworkPortAssignment was successfully updated.'
        format.html { redirect_to ip_address_network_port_assignment_url(@ip_address_network_port_assignment) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @ip_address_network_port_assignment.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /ip_address_network_port_assignments/1
  # DELETE /ip_address_network_port_assignments/1.xml
  def destroy
    @ip_address_network_port_assignment = @object
    @ip_address = @ip_address_network_port_assignment.ip_address
    return unless filter_perms(@auth,@ip_address,['updater'])
    @network_port = @ip_address_network_port_assignment.network_port
    return unless filter_perms(@auth,@network_port,['updater'])
    @ip_address_network_port_assignment.destroy

    respond_to do |format|
      format.html { redirect_to ip_address_network_port_assignments_url }
      format.xml  { head :ok }
    end
  end
  
  # GET /ip_address_network_port_assignments/1/version_history
  def version_history
    @ip_address_network_port_assignment = IpAddressNetworkPortAssignment.find(params[:id])
    render :action => "version_table", :layout => false
  end
  
end
