class GraffitisController < ApplicationController
  # sets the @auth object and @object
  before_filter :get_obj_auth
  before_filter :modelperms

  # GET /graffitis
  # GET /graffitis.xml
  def index
    special_joins = {}

    ## BUILD MASTER HASH WITH ALL SUB-PARAMS ##
    allparams = {}
    allparams[:mainmodel] = Graffiti
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

  # GET /graffitis/1
  # GET /graffitis/1.xml
  def show
    @graffiti = @object

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @graffiti.to_xml(:include => convert_includes(includes),
                                                  :dasherize => false) }
    end
  end

  # GET /graffitis/new
  def new
    @graffiti = @object
  end

  # GET /graffitis/1/edit
  def edit
    @graffiti = @object
  end

  # POST /graffitis
  # POST /graffitis.xml
  def create
    @graffiti = Graffiti.new(params[:graffiti])

    respond_to do |format|
      if @graffiti.save
        flash[:notice] = 'Graffiti was successfully created.'
        format.html { redirect_to graffiti_url(@graffiti) }
        format.xml  { head :created, :location => graffiti_url(@graffiti) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @graffiti.errors.to_xml, :graffiti => :unprocessable_entity }
      end
    end
  end

  # PUT /graffitis/1
  # PUT /graffitis/1.xml
  def update
    @graffiti = @object

    respond_to do |format|
      if @graffiti.update_attributes(params[:graffiti])
        flash[:notice] = 'Graffiti was successfully updated.'
        format.html { redirect_to graffiti_url(@graffiti) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @graffiti.errors.to_xml, :graffiti => :unprocessable_entity }
      end
    end
  end

  # DELETE /graffitis/1
  # DELETE /graffitis/1.xml
  def destroy
    @graffiti = @object
    @graffiti.destroy
    flash[:error] = @graffiti.errors.on_base unless @graffiti.errors.empty?

    respond_to do |format|
      format.html { redirect_to graffitis_url }
      format.xml  { head :ok }
    end
  end
  
  # GET /graffitis/1/version_history
  def version_history
    @graffiti = Graffiti.find(params[:id])
    render :action => "version_table", :layout => false
  end
  
  # GET /graffitis/field_names
  def field_names
    super(Graffiti)
  end

  # GET /graffitis/search
  def search
    @graffiti = Graffiti.find(:first)
    render :action => 'search'
  end
  
end
