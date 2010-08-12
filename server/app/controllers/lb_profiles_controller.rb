class LbProfilesController < ApplicationController
  # sets the @auth object and @object
  before_filter :get_obj_auth
  before_filter :modelperms

  # GET /lb_profiles
  # GET /lb_profiles.xml
  $lbmethods = %w[ round_robin ratio_member dynamic_ratio fastest_member least_conn_member observed_member predictive_member ]
  $protocols = %w[ tcp udp both ]

  def index
    special_joins = {}

    ## BUILD MASTER HASH WITH ALL SUB-PARAMS ##
    allparams = {}
    allparams[:mainmodel] = LbProfile
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

  # GET /lb_profiles/1
  # GET /lb_profiles/1.xml
  def show
    @lb_profile = @object

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @lb_profile.to_xml(:include => convert_includes(includes),
                                                      :dasherize => false) }
    end
  end

  # GET /lb_profiles/new
  def new
    @lb_profile = @object
    respond_to do |format|
      format.html # show.html.erb
      format.js  { render :action => "inline_new", :layout => false }
    end
  end

  # GET /lb_profiles/1/edit
  def edit
    @lb_profile = @object
  end

  # POST /lb_profiles
  # POST /lb_profiles.xml
  def create
    @lb_profile = LbProfile.new(params[:lb_profile])

    respond_to do |format|
      if @lb_profile.save
        flash[:notice] = 'Load Balancer Profile was successfully created.'
        format.html { redirect_to lb_profile_url(@lb_profile) }
        format.xml  { head :created, :location => lb_profile_url(@lb_profile) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @lb_profile.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /lb_profiles/1
  # PUT /lb_profiles/1.xml
  def update
    @lb_profile = @object

    respond_to do |format|
      if @lb_profile.update_attributes(params[:lb_profile])
        flash[:notice] = 'Load Balancer Profile was successfully updated.'
        format.html { redirect_to lb_profile_url(@lb_profile) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @lb_profile.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /lb_profiles/1
  # DELETE /lb_profiles/1.xml
  def destroy
    @lb_profile = @object
    @lb_profile.destroy

    respond_to do |format|
      format.html { redirect_to lb_profiles_url }
      format.xml  { head :ok }
    end
  end
  
  # GET /lb_profiles/1/version_history
  def version_history
    @lb_profile = LbProfile.find(params[:id])
    render :action => "version_table", :layout => false
  end
  
  # GET /lb_profiles/field_names
  def field_names
    super(LbProfile)
  end

  # GET /lb_profiles/search
  def search
    @lb_profile = LbProfile.find(:first)
    render :action => 'search'
  end
  
end
