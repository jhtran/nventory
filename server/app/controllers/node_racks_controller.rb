class NodeRacksController < ApplicationController
  # GET /node_racks
  # GET /node_racks.xml
  def index
    includes = process_includes(NodeRack, params[:include])
    
    sort = case params['sort']
           when "name" then "node_racks.name"
           when "name_reverse" then "node_racks.name DESC"
           end
    
    # if a sort was not defined we'll make one default
    if sort.nil?
      params['sort'] = NodeRack.default_search_attribute
      sort = 'node_racks.' + NodeRack.default_search_attribute
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
      @objects = NodeRack.find(:all,
                           :include => includes,
                           :order => sort)
    else
      @objects = NodeRack.paginate(:all,
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

  # GET /node_racks/1
  # GET /node_racks/1.xml
  def show
    includes = process_includes(NodeRack, params[:include])
    
    @node_rack = NodeRack.find(params[:id],
                      :include => includes)

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @node_rack.to_xml(:include => convert_includes(includes),
                                                :dasherize => false) }
    end
  end

  # GET /racks/new
  def new
    @node_rack = NodeRack.new
    respond_to do |format|
      format.html # show.html.erb
      format.js  { render :action => "inline_new", :layout => false }
    end
  end

  # GET /racks/1/edit
  def edit
    @node_rack = NodeRack.find(params[:id])
  end

  # POST /racks
  # POST /racks.xml
  def create
    @node_rack = NodeRack.new(params[:node_rack])

    respond_to do |format|
      if @node_rack.save
        flash[:notice] = 'NodeRack was successfully created.'
        format.html { redirect_to node_rack_url(@node_rack) }
        format.js { 
          render(:update) { |page| 
            page.replace_html 'create_rack_assignment', :partial => 'shared/create_assignment', :locals => { :from => 'datacenter', :to => 'node_rack' }
            page['datacenter_node_rack_assignment_rack_id'].value = @node_rack.id
            page.hide 'new_node_rack'
            
            # WORKAROUND: We have to manually escape the single quotes here due to a bug in rails:
            # http://dev.rubyonrails.org/ticket/5751
            page.visual_effect :highlight, 'create_rack_assignment', :startcolor => "\'"+RELATIONSHIP_HIGHLIGHT_START_COLOR+"\'", :endcolor => "\'"+RELATIONSHIP_HIGHLIGHT_END_COLOR+"\'", :restorecolor => "\'"+RELATIONSHIP_HIGHLIGHT_RESTORE_COLOR+"\'"
            
          }
        }
        format.xml  { head :created, :location => node_rack_url(@node_rack) }
      else
        format.html { render :action => "new" }
        format.js   { render(:update) { |page| page.alert(@node_rack.errors.full_messages) } }
        format.xml  { render :xml => @node_rack.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /node_racks/1
  # PUT /node_racks/1.xml
  def update
    @node_rack = NodeRack.find(params[:id])

    respond_to do |format|
      if @node_rack.update_attributes(params[:node_rack])
        flash[:notice] = 'NodeRack was successfully updated.'
        format.html { redirect_to node_rack_url(@node_rack) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @node_rack.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /node_racks/1
  # DELETE /node_racks/1.xml
  def destroy
    @node_rack = NodeRack.find(params[:id])
    begin
      @node_rack.destroy
    rescue Exception => destroy_error
      respond_to do |format|
        flash[:error] = destroy_error.message
        format.html { redirect_to node_rack_url(@node_rack) and return}
        format.xml  { head :error } # FIXME?
      end
    end
    
    # Success!
    respond_to do |format|
      format.html { redirect_to node_racks_url }
      format.xml  { head :ok }
    end
  end
  
  # GET /node_racks/1/version_history
  def version_history
    @node_rack = NodeRack.find(params[:id])
    render :action => "version_table", :layout => false
  end
  
  # GET /node_racks/1/visualization
  def visualization
    @node_rack = NodeRack.find(params[:id])
  end
  
  # GET /node_racks/field_names
  def field_names
    super(NodeRack)
  end

  # GET /node_racks/search
  def search
    @node_rack = NodeRack.find(:first)
    render :action => 'search'
  end
  
end
