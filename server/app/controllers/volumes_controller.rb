class VolumesController < ApplicationController
  # GET /volumes
  # GET /volumes.xml
  def index
    includes = process_includes(Volume, params[:include])
    
    sort = case params['sort']
           when "name" then "volumes.name"
           when "name_reverse" then "volumes.name DESC"
           end
    
    # if a sort was not defined we'll make one default
    if sort.nil?
      params['sort'] = Volume.default_search_attribute
      sort = 'volumes.' + Volume.default_search_attribute
    end
    
    # The index page includes some data from associations.  If we don't
    # include those associations then N SQL calls result as that data is
    # looked up row by row.
    if !params[:format] || params[:format] == 'html'
      # FIXME: Including has_one, through is not supported, see note in
      # process_includes for more details
      #includes[:datacenter] = {}
      # Need to include the node's hardware profile as that is used
      # in calculating the free/used space columns
      # FIXME: not sure why this stopped working
      #includes[[:nodes => :hardware_profile]] = {}
    end

    # XML doesn't get pagination
    if params[:format] && params[:format] == 'xml'
      @objects = Volume.find(:all,
                           :include => includes,
                           :order => sort)
    else
      @objects = Volume.paginate(:all,
                               :include => includes,
                               :order => sort,
                               :page => params[:page])
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @objects.to_xml(:include => convert_includes(includes),
                                                   :dasherize => false) }
    end
  end

  # GET /volumes/1
  # GET /volumes/1.xml
  def show
    includes = process_includes(Volume, params[:include])
    
    @volume = Volume.find(params[:id],
                      :include => includes)

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @volume.to_xml(:include => convert_includes(includes),
                                                :dasherize => false) }
    end
  end

  # GET /volumes/new
  def new
    @volume = Volume.new
    @volume_servers = Node.find(:all, :select => 'id, name', :order => 'name').map{|node| [node.name,node.id]}
    respond_to do |format|
      format.html # show.html.erb
      format.js  { render :action => "inline_new", :layout => false }
    end
  end

  # GET /volumes/1/edit
  def edit
    @volume = Volume.find(params[:id])
    @volume_servers = Node.find(:all, :select => 'id, name', :order => 'name').map{|node| [node.name,node.id]}
  end

  # POST /volumes
  # POST /volumes.xml
  def create
    @volume = Volume.new(params[:volume])
    respond_to do |format|
      if @volume.save
        flash[:notice] = 'Volume was successfully created.'
        format.html { redirect_to volume_url(@volume) }
        format.js { 
          render(:update) { |page| 
            if request.env["HTTP_REFERER"].include? "nodes"
              page.replace_html 'volume_served', :partial => 'nodes/volume_served', :locals => { :node => @volume.volume_server }
              page.hide 'create_volume_served'
              page.hide 'no_volumes'
              page.show 'add_volume_served_link'
            else
              page.hide 'new_volume'
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
    @volume = Volume.find(params[:id])

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
    @volume = Volume.find(params[:id])
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
