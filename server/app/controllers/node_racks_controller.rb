class NodeRacksController < ApplicationController
  # sets the @auth object and @object
  before_filter :get_obj_auth
  before_filter :modelperms

  # GET /node_racks
  # GET /node_racks.xml
  def index
    ## BUILD MASTER HASH WITH ALL SUB-PARAMS ##
    allparams = {}
    allparams[:mainmodel] = NodeRack
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

  # GET /node_racks/1
  # GET /node_racks/1.xml
  def show
    @node_rack = @object

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @node_rack.to_xml(:include => convert_includes(includes),
                                                :dasherize => false) }
    end
  end

  # GET /racks/new
  def new
    @node_rack = @object
    respond_to do |format|
      format.html # show.html.erb
      format.js  { render :action => "inline_new", :layout => false }
    end
  end

  # GET /racks/1/edit
  def edit
    @node_rack = @object
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
    @node_rack = @object

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
    @node_rack = @object
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
