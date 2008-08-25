class HardwareProfilesController < ApplicationController
  # GET /hardware_profiles
  # GET /hardware_profiles.xml
  def index
    sort = case params['sort']
           when "name" then "hardware_profiles.name"
           when "name_reverse" then "hardware_profiles.name DESC"
           end
    
    # if a sort was not defined we'll make one default
    if sort.nil?
      params['sort'] = HardwareProfile.default_search_attribute
      sort = 'hardware_profiles.' + HardwareProfile.default_search_attribute
    end
    
    # XML doesn't get pagination
    if params[:format] && params[:format] == 'xml'
      @objects = HardwareProfile.find(:all, :order => sort)
    else
      @objects = HardwareProfile.paginate(:all,
                                          :order => sort,
                                          :page => params[:page])
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @objects.to_xml(:dasherize => false) }
    end
  end

  # GET /hardware_profiles/1
  # GET /hardware_profiles/1.xml
  def show
    @hardware_profile = HardwareProfile.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @hardware_profile.to_xml(:dasherize => false) }
    end
  end

  # GET /hardware_profiles/new
  def new
    @hardware_profile = HardwareProfile.new
  end

  # GET /hardware_profiles/1/edit
  def edit
    @hardware_profile = HardwareProfile.find(params[:id])
  end

  # POST /hardware_profiles
  # POST /hardware_profiles.xml
  def create
    @hardware_profile = HardwareProfile.new(params[:hardware_profile])

    respond_to do |format|
      if @hardware_profile.save
        flash[:notice] = 'HardwareProfile was successfully created.'
        format.html { redirect_to hardware_profile_url(@hardware_profile) }
        format.xml  { head :created, :location => hardware_profile_url(@hardware_profile) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @hardware_profile.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /hardware_profiles/1
  # PUT /hardware_profiles/1.xml
  def update
    @hardware_profile = HardwareProfile.find(params[:id])

    respond_to do |format|
      if @hardware_profile.update_attributes(params[:hardware_profile])
        flash[:notice] = 'HardwareProfile was successfully updated.'
        format.html { redirect_to hardware_profile_url(@hardware_profile) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @hardware_profile.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /hardware_profiles/1
  # DELETE /hardware_profiles/1.xml
  def destroy
    @hardware_profile = HardwareProfile.find(params[:id])
    @hardware_profile.destroy

    respond_to do |format|
      format.html { redirect_to hardware_profiles_url }
      format.xml  { head :ok }
    end
  end
  
  # GET /hardware_profiles/1/version_history
  def version_history
    @hardware_profile = HardwareProfile.find_with_deleted(params[:id])
    render :action => "version_table", :layout => false
  end
  
  # GET /hardware_profiles/field_names
  def field_names
    super(HardwareProfile)
  end

  # GET /hardware_profiles/search
  def search
    @hardware_profile = HardwareProfile.find(:first)
    render :action => 'search'
  end
  
end
