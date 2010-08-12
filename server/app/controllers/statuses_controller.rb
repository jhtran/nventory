class StatusesController < ApplicationController
  # sets the @auth object and @object
  before_filter :get_obj_auth
  before_filter :modelperms

  # GET /statuses
  # GET /statuses.xml
  def index
    special_joins = {}

    ## BUILD MASTER HASH WITH ALL SUB-PARAMS ##
    allparams = {}
    allparams[:mainmodel] = Status
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

  # GET /statuses/1
  # GET /statuses/1.xml
  def show
    @status = @object

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @status.to_xml(:include => convert_includes(includes),
                                                  :dasherize => false) }
    end
  end

  # GET /statuses/new
  def new
    @status = @object
  end

  # GET /statuses/1/edit
  def edit
    @status = @object
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
    @status = @object

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
    @status = @object
    @status.destroy
    flash[:error] = @status.errors.on_base unless @status.errors.empty?

    respond_to do |format|
      format.html { redirect_to statuses_url }
      format.xml  { head :ok }
    end
  end
  
  # GET /statuses/1/version_history
  def version_history
    @status = Status.find(params[:id])
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
