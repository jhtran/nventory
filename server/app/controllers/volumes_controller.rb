class VolumesController < ApplicationController
  # sets the @auth object and @object
  before_filter :get_obj_auth
  before_filter :modelperms

  # GET /volumes
  # GET /volumes.xml
  def index
    ## BUILD MASTER HASH WITH ALL SUB-PARAMS ##
    allparams = {}
    allparams[:mainmodel] = Volume
    allparams[:webparams] = params
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

  # GET /volumes/1
  # GET /volumes/1.xml
  def show
    @volume = @object

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @volume.to_xml(:include => convert_includes(includes),
                                                :dasherize => false) }
    end
  end

  # GET /volumes/new
  def new
    @volume = @object
    @volume_servers = Node.find(:all, :select => 'id, name', :order => 'name').map{|node| [node.name,node.id]}
    respond_to do |format|
      format.html # show.html.erb
      format.js  { render :action => "inline_new", :layout => false }
    end
  end

  # GET /volumes/1/edit
  def edit
    @volume = @object
    @volume_servers = Node.find(:all, :select => 'id, name', :order => 'name').map{|node| [node.name,node.id]}
  end

  # POST /volumes
  # POST /volumes.xml
  def create
    if params[:volume][:volume_server_id]
      volume_server = Node.find(params[:volume][:volume_server_id])
      return unless filter_perms(@auth,volume_server,['updater'])
    else
      return unless filter_perms(@auth,Volume,['creator'])
    end
    @volume = Volume.new(params[:volume])
    @volume_servers = Node.find(:all, :select => 'id, name', :order => 'name').map{|node| [node.name,node.id]}
    respond_to do |format|
      if @volume.save
        flash[:notice] = 'Volume was successfully created.'
        format.html { redirect_to volume_url(@volume) }
        format.js { 
          render(:update) { |page| 
            if request.env["HTTP_REFERER"].include? "nodes"
              page.replace_html 'volume_served', :partial => 'nodes/volume_served', :locals => { :node => @volume.volume_server }
            end
          }
        }
        format.xml  { head :created, :location => volume_url(@volume) }
      else
        format.html { render :action => "new" }
        format.js   { render(:update) { |page| page.alert(@volume.errors.full_messages) } }
        format.xml  { render :xml => @volume.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /volumes/1
  # PUT /volumes/1.xml
  def update
    @volume = @object
    @volume.volume_server ? (return unless filter_perms(@auth,@volume.volume_server,['updater'])) : (return unless filter_perms(@auth,@volume,['updater']))

    respond_to do |format|
      if @volume.update_attributes(params[:volume])
        flash[:notice] = 'Volume was successfully updated.'
        format.html { redirect_to volume_url(@volume) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @volume.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /volumes/1
  # DELETE /volumes/1.xml
  def destroy
    @volume = @object
    @volume.volume_server ? (return unless filter_perms(@auth,@volume.volume_server,['updater'])) : (return unless filter_perms(@auth,@volume,['destroyer']))
    begin
      @volume.destroy
    rescue Exception => destroy_error
      respond_to do |format|
        flash[:error] = destroy_error.message
        format.html { redirect_to volume_url(@volume) and return}
        format.xml  { head :error } # FIXME?
      end
    end
    
    # Success!
    respond_to do |format|
      format.html { redirect_to volumes_url }
      format.js {
         render(:update) { |page|
          if request.env["HTTP_REFERER"].include? "nodes"
            page.replace_html 'volume_served', {:partial => 'nodes/volume_served', :locals => { :node => @volume.volume_server } }
            page.hide 'create_volume_served'
            page.show 'add_volume_served_link'
          end
         }
      }
      format.xml  { head :ok }
    end
  end
  
  # GET /volumes/1/version_history
  def version_history
    @volume = Volume.find(params[:id])
    render :action => "version_table", :layout => false
  end
  
  # GET /volumes/1/visualization
  def visualization
    @volume = Volume.find(params[:id])
  end
  
  # GET /volumes/field_names
  def field_names
    super(Volume)
  end

  # GET /volumes/search
  def search
    @volume = Volume.find(:first)
    render :action => 'search'
  end
  
end
