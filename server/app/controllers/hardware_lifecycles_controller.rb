class HardwareLifecyclesController < ApplicationController
  # sets the @auth object and @object
  before_filter :get_obj_auth
  before_filter :modelperms

  # GET /hardware_lifecycles
  # GET /hardware_lifecycles.xml
  def index
    ## BUILD MASTER HASH WITH ALL SUB-PARAMS ##
    allparams = {}
    allparams[:mainmodel] = HardwareLifecycle
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

  # GET /hardware_lifecycles/1
  # GET /hardware_lifecycles/1.xml
  def show
    @hardware_lifecycle = @object

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @hardware_lifecycle.to_xml(:dasherize => false) }
    end
  end

  # GET /hardware_lifecycles/1/version_history
  def version_history
    @hardware_lifecycle = HardwareLifecycle.find(params[:id])
    render :action => "version_table", :layout => false
  end

  # GET /hardware_lifecycles/1/edit
  def edit
    @hardware_lifecycle = @object
  end

  # PUT /hardware_lifecycles/1
  # PUT /hardware_lifecycles/1.xml
  def update
    @hardware_lifecycle = @object
    @node = @hardware_lifecycle.node
    return unless filter_perms(@auth,@hardware_lifecycle,['updater'])
    return unless filter_perms(@auth,@node,['updater'])

    respond_to do |format|
      if @hardware_lifecycle.update_attributes(params[:hardware_lifecycle])
        flash[:notice] = 'HardwareLifecycle was successfully updated.'
        format.html { redirect_to hardware_lifecycle_url(@hardware_lifecycle) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @hardware_lifecycle.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /hardware_lifecycles/1
  # DELETE /hardware_lifecycles/1.xml
  def destroy
    @hardware_lifecycle = @object
    @node = @hardware_lifecycle.node
    return unless filter_perms(@auth,@hardware_lifecycle,['updater'])
    return unless filter_perms(@auth,@node,['updater'])

    begin
      @hardware_lifecycle.destroy
    rescue Exception => destroy_error
      respond_to do |format|
        format.html {
          flash[:error] = destroy_error.message
          redirect_to hardware_lifecycle_url(@hardware_lifecycle) and return
        }
      end
      return
    end

    # Success!
    respond_to do |format|
      format.html { redirect_to hardware_lifecycles_url }
      format.xml  { head :ok }
    end
  end

  def new
    render :text => "Please use the Node page to create new hardware lifecycle assignment."
  end

  # GET /hardware_lifecycles/field_names
  def field_names
    super(HardwareLifecycle)
  end
end
