class RacksController < ApplicationController
  # GET /racks
  # GET /racks.xml
  def index
    includes = process_includes(Rack, params[:include])
    
    sort = case params['sort']
           when "name" then "racks.name"
           when "name_reverse" then "racks.name DESC"
           end
    
    # if a sort was not defined we'll make one default
    if sort.nil?
      params['sort'] = Rack.default_search_attribute
      sort = 'racks.' + Rack.default_search_attribute
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
      @objects = Rack.find(:all,
                           :include => includes,
                           :order => sort)
    else
      @objects = Rack.paginate(:all,
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

  # GET /racks/1
  # GET /racks/1.xml
  def show
    includes = process_includes(Rack, params[:include])
    
    @rack = Rack.find(params[:id],
                      :include => includes)

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @rack.to_xml(:include => convert_includes(includes),
                                                :dasherize => false) }
    end
  end

  # GET /racks/new
  def new
    @rack = Rack.new
    respond_to do |format|
      format.html # show.html.erb
      format.js  { render :action => "inline_new", :layout => false }
    end
  end

  # GET /racks/1/edit
  def edit
    @rack = Rack.find(params[:id])
  end

  # POST /racks
  # POST /racks.xml
  def create
    @rack = Rack.new(params[:rack])

    respond_to do |format|
      if @rack.save
        flash[:notice] = 'Rack was successfully created.'
        format.html { redirect_to rack_url(@rack) }
        format.js { 
          render(:update) { |page| 
            page.replace_html 'create_rack_assignment', :partial => 'shared/create_assignment', :locals => { :from => 'datacenter', :to => 'rack' }
            page['datacenter_rack_assignment_rack_id'].value = @rack.id
            page.hide 'new_rack'
            
            # WORKAROUND: We have to manually escape the single quotes here due to a bug in rails:
            # http://dev.rubyonrails.org/ticket/5751
            page.visual_effect :highlight, 'create_rack_assignment', :startcolor => "\'"+RELATIONSHIP_HIGHLIGHT_START_COLOR+"\'", :endcolor => "\'"+RELATIONSHIP_HIGHLIGHT_END_COLOR+"\'", :restorecolor => "\'"+RELATIONSHIP_HIGHLIGHT_RESTORE_COLOR+"\'"
            
          }
        }
        format.xml  { head :created, :location => rack_url(@rack) }
      else
        format.html { render :action => "new" }
        format.js   { render(:update) { |page| page.alert(@rack.errors.full_messages) } }
        format.xml  { render :xml => @rack.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /racks/1
  # PUT /racks/1.xml
  def update
    @rack = Rack.find(params[:id])

    respond_to do |format|
      if @rack.update_attributes(params[:rack])
        flash[:notice] = 'Rack was successfully updated.'
        format.html { redirect_to rack_url(@rack) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @rack.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /racks/1
  # DELETE /racks/1.xml
  def destroy
    @rack = Rack.find(params[:id])
    begin
      @rack.destroy
    rescue Exception => destroy_error
      respond_to do |format|
        flash[:error] = destroy_error.message
        format.html { redirect_to rack_url(@rack) and return}
        format.xml  { head :error } # FIXME?
      end
    end
    
    # Success!
    respond_to do |format|
      format.html { redirect_to racks_url }
      format.xml  { head :ok }
    end
  end
  
  # GET /racks/1/version_history
  def version_history
    @rack = Rack.find(params[:id])
    render :action => "version_table", :layout => false
  end
  
  # GET /racks/1/visualization
  def visualization
    @rack = Rack.find(params[:id])
  end
  
  # GET /racks/field_names
  def field_names
    super(Rack)
  end

  # GET /racks/search
  def search
    @rack = Rack.find(:first)
    render :action => 'search'
  end
  
end
