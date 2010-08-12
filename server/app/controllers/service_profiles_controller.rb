class ServiceProfilesController < ApplicationController
  # sets the @auth object and @object
  before_filter :get_obj_auth
  before_filter :modelperms

  # GET /service_profiles
  # GET /service_profiles.xml
  def index
    special_joins = {}

    ## BUILD MASTER HASH WITH ALL SUB-PARAMS ##
    allparams = {}
    allparams[:mainmodel] = ServiceProfile
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

  # GET /service_profiles/1
  # GET /service_profiles/1.xml
  def show
    @service_profile = @object

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @service_profile.to_xml(:include => convert_includes(includes),
                                                      :dasherize => false) }
    end
  end

  # GET /service_profiles/new
  def new
    @services = Service.find(:all, :select => 'id,name', :order => 'name').collect{|service| [service.name,service.id]}
    @service_profile = @object
    respond_to do |format|
      format.html # show.html.erb
      format.js  { render :action => "inline_new", :layout => false }
    end
  end

  # GET /service_profiles/1/edit
  def edit
    @services = Service.find(:all, :select => 'id,name', :order => 'name').collect{|service| [service.name,service.id]}
    @service_profile = @object
  end

  # POST /service_profiles
  # POST /service_profiles.xml
  def create
    @services = Service.find(:all, :select => 'id,name', :order => 'name').collect{|service| [service.name,service.id]}
    @service_profile = ServiceProfile.new(params[:service_profile])

    respond_to do |format|
      if @service_profile.save
        flash[:notice] = 'Service Profile was successfully created.'
        format.html { redirect_to service_profile_url(@service_profile) }
        format.xml  { head :created, :location => service_profile_url(@service_profile) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @service_profile.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /service_profiles/1
  # PUT /service_profiles/1.xml
  def update
    @services = Service.find(:all, :select => 'id,name', :order => 'name').collect{|service| [service.name,service.id]}
    @service_profile = @object

    respond_to do |format|
      if @service_profile.update_attributes(params[:service_profile])
        flash[:notice] = 'Service Profile was successfully updated.'
        format.html { redirect_to service_profile_url(@service_profile) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @service_profile.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /service_profiles/1
  # DELETE /service_profiles/1.xml
  def destroy
    @service_profile = @object
    @service_profile.destroy

    respond_to do |format|
      format.html { redirect_to service_profiles_url }
      format.xml  { head :ok }
    end
  end
  
  # GET /service_profiles/1/version_history
  def version_history
    @service_profile = ServiceProfile.find(params[:id])
    render :action => "version_table", :layout => false
  end
  
  # GET /service_profiles/field_names
  def field_names
    super(ServiceProfile)
  end

  # GET /service_profiles/search
  def search
    @service_profile = ServiceProfile.find(:first)
    render :action => 'search'
  end
  
end
