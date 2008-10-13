class StatusesController < ApplicationController
  # GET /statuses
  # GET /statuses.xml
  def index
    includes = process_includes(Status, params[:include])
    
    sort = case params['sort']
           when "name" then "statuses.name"
           when "name_reverse" then "statuses.name DESC"
           end
    
    # if a sort was not defined we'll make one default
    if sort.nil?
      params['sort'] = Status.default_search_attribute
      sort = 'statuses.' + Status.default_search_attribute
    end
    
    # XML doesn't get pagination
    if params[:format] && params[:format] == 'xml'
      @objects = Status.find(:all,
                             :include => includes,
                             :order => sort)
    else
      @objects = Status.paginate(:all,
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

  # GET /statuses/1
  # GET /statuses/1.xml
  def show
    includes = process_includes(Status, params[:include])
    
    @status = Status.find(params[:id],
                          :include => includes)

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @status.to_xml(:include => convert_includes(includes),
                                                  :dasherize => false) }
    end
  end

  # GET /statuses/new
  def new
    @status = Status.new
  end

  # GET /statuses/1/edit
  def edit
    @status = Status.find(params[:id])
  end

  # POST /statuses
  # POST /statuses.xml
  def create
    @status = Status.new(params[:status])

    respond_to do |format|
      if @status.save
        flash[:notice] = 'Status was successfully created.'
        format.html { redirect_to status_url(@status) }
        format.xml  { head :created, :location => status_url(@status) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @status.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /statuses/1
  # PUT /statuses/1.xml
  def update
    @status = Status.find(params[:id])

    respond_to do |format|
      if @status.update_attributes(params[:status])
        flash[:notice] = 'Status was successfully updated.'
        format.html { redirect_to status_url(@status) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @status.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /statuses/1
  # DELETE /statuses/1.xml
  def destroy
    @status = Status.find(params[:id])
    @status.destroy

    respond_to do |format|
      format.html { redirect_to statuses_url }
      format.xml  { head :ok }
    end
  end
  
  # GET /statuses/1/version_history
  def version_history
    @status = Status.find_with_deleted(params[:id])
    render :action => "version_table", :layout => false
  end
  
  # GET /statuses/field_names
  def field_names
    super(Status)
  end

  # GET /statuses/search
  def search
    @status = Status.find(:first)
    render :action => 'search'
  end
  
end
