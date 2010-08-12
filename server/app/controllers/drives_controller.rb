class DrivesController < ApplicationController
  # sets the @auth object and @object
  before_filter :get_obj_auth
  before_filter :modelperms

  $drive_types = %w(nfs ext3 ext2 ext4 smb)
  # GET /drives
  # GET /drives.xml
  def index
    ## BUILD MASTER HASH WITH ALL SUB-PARAMS ##
    allparams = {}
    allparams[:mainmodel] = Drive
    allparams[:webparams] = params
    results = Search.new(allparams).search

    flash[:error] = results[:errors].join('<br />') unless results[:errors].empty?
    includes = results[:includes]
    results[:requested_includes].each_pair{|k,v| includes[k] = v}
    @objects = results[:search_results]

    # search results should contain csvobj which contains all the params for building and put it in session.  View will launch csv controller to call on that session
    if @csvon == "true"
      results[:csvobj]['def_attr_names'] = Node.default_includes
      session[:csvobj] = results[:csvobj]
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @objects.to_xml(:include => convert_includes(includes),
                                                   :dasherize => false) }
    end
  end

  # GET /drives/1
  # GET /drives/1.xml
  def show
    @drive = @object

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @drive.to_xml(:include => convert_includes(includes),
                                                :dasherize => false) }
    end
  end

  # GET /drives/new
  def new
    @drive = @object
    respond_to do |format|
      format.html # show.html.erb
      format.js  { render :action => "inline_new", :layout => false }
    end
  end

  # GET /drives/1/edit
  def edit
    @drive = @object
  end

  # POST /drives
  # POST /drives.xml
  def create
    @drive = @object
    respond_to do |format|
      if @drive.save
        flash[:notice] = 'Drive was successfully created.'
        format.html { redirect_to drive_url(@drive) }
        format.js { 
          render(:update) { |page| 
            if request.env["HTTP_REFERER"].include? "nodes"
              page.replace_html 'drive_served', :partial => 'nodes/drive_served', :locals => { :node => @drive.drive_server }
              page.hide 'create_drive_served'
              page.hide 'no_drives'
              page.show 'add_drive_served_link'
            else
              page.hide 'new_drive'
            end
          }
        }
        format.xml  { head :created, :location => drive_url(@drive) }
      else
        format.html { render :action => "new" }
        format.js   { render(:update) { |page| page.alert(@drive.errors.full_messages) } }
        format.xml  { render :xml => @drive.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /drives/1
  # PUT /drives/1.xml
  def update
    @drive = @object

    respond_to do |format|
      if @drive.update_attributes(params[:drive])
        flash[:notice] = 'Drive was successfully updated.'
        format.html { redirect_to drive_url(@drive) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @drive.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /drives/1
  # DELETE /drives/1.xml
  def destroy
    @drive = @object
    begin
      @drive.destroy
    rescue Exception => destroy_error
      respond_to do |format|
        flash[:error] = destroy_error.message
        format.html { redirect_to drive_url(@drive) and return}
        format.xml  { head :error } # FIXME?
      end
    end
    
    # Success!
    respond_to do |format|
      format.html { redirect_to drives_url }
      format.js {
         render(:update) { |page|
          if request.env["HTTP_REFERER"].include? "nodes"
            page.replace_html 'drive_served', {:partial => 'nodes/drive_served', :locals => { :node => @drive.drive_server } }
            page.hide 'create_drive_served'
            page.show 'add_drive_served_link'
          end
         }
      }
      format.xml  { head :ok }
    end
  end
  
  # GET /drives/1/version_history
  def version_history
    @drive = Drive.find(params[:id])
    render :action => "version_table", :layout => false
  end
  
  # GET /drives/1/visualization
  def visualization
    @drive = Drive.find(params[:id])
  end
  
  # GET /drives/field_names
  def field_names
    super(Drive)
  end

  # GET /drives/search
  def search
    @drive = Drive.find(:first)
    render :action => 'search'
  end
  
end
