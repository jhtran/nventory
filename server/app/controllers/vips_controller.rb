class VipsController < ApplicationController
  # GET /vips
  # GET /vips.xml
  def index
    sort = case params['sort']
           when "name" then "vips.name"
           when "name_reverse" then "vips.name DESC"
           end
    
    # if a sort was not defined we'll make one default
    if sort.nil?
      params['sort'] = Vip.default_search_attribute
      sort = 'vips.' + Vip.default_search_attribute
    end
    
    # XML doesn't get pagination
    if params[:format] && params[:format] == 'xml'
      @objects = Vip.find(:all, :order => sort)
    else
      @objects = Vip.paginate(:all,
                          :order => sort,
                          :page => params[:page])
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @objects.to_xml(:include => [:node_group, :datacenter_vip_assignments], :dasherize => false) }
    end
  end

  # GET /vips/1
  # GET /vips/1.xml
  def show
    @vip = Vip.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @vip.to_xml(:include => [:node_group, :datacenter_vip_assignments], :dasherize => false) }
    end
  end

  # GET /vips/new
  def new
    @vip = Vip.new
  end

  # GET /vips/1/edit
  def edit
    @vip = Vip.find(params[:id])
  end

  # POST /vips
  # POST /vips.xml
  def create
    @vip = Vip.new(params[:vip])

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
    @vip = Vip.find(params[:id])

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
    @vip = Vip.find(params[:id])
    @vip.destroy

    respond_to do |format|
      format.html { redirect_to vips_url }
      format.xml  { head :ok }
    end
  end
  
  # GET /vips/1/version_history
  def version_history
    @vip = Vip.find_with_deleted(params[:id])
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
