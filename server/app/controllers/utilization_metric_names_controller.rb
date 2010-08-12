class UtilizationMetricNamesController < ApplicationController
  # sets the @auth object and @object
  before_filter :get_obj_auth
  before_filter :modelperms

  # GET /utilization_metric_names
  # GET /utilization_metric_names.xml
  def index
    special_joins = {}

    ## BUILD MASTER HASH WITH ALL SUB-PARAMS ##
    allparams = {}
    allparams[:mainmodel] = UtilizationMetricName
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

  # GET /utilization_metric_names/1
  # GET /utilization_metric_names/1.xml
  def show
    @utilization_metric_name = @object

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @utilization_metric_name.to_xml(:include => convert_includes(includes),
                                                  :dasherize => false) }
    end
  end

  # GET /utilization_metric_names/new
  def new
    @utilization_metric_name = @object
  end

  # GET /utilization_metric_names/1/edit
  def edit
    @utilization_metric_name = @object
  end

  # POST /utilization_metric_names
  # POST /utilization_metric_names.xml
  def create
    @utilization_metric_name = UtilizationMetricName.new(params[:utilization_metric_name])

    respond_to do |format|
      if @utilization_metric_name.save
        flash[:notice] = 'UtilizationMetricName was successfully created.'
        format.html { redirect_to utilization_metric_name_url(@UtilizationMetricName) }
        format.xml  { head :created, :location => utilization_metric_name_url(@UtilizationMetricName) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @UtilizationMetricName.errors.to_xml, :utilization_metric_name => :unprocessable_entity }
      end
    end
  end

  # PUT /utilization_metric_names/1
  # PUT /utilization_metric_names/1.xml
  def update
    @utilization_metric_name = @object

    respond_to do |format|
      if @utilization_metric_name.update_attributes(params[:utilization_metric_name])
        flash[:notice] = 'UtilizationMetricName was successfully updated.'
        format.html { redirect_to utilization_metric_name_url(@utilization_metric_name) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @utilization_metric_name.errors.to_xml, :utilization_metric_name => :unprocessable_entity }
      end
    end
  end

  # DELETE /utilization_metric_names/1
  # DELETE /utilization_metric_names/1.xml
  def destroy
    @utilization_metric_name = @object
    @utilization_metric_name.destroy

    respond_to do |format|
      format.html { redirect_to utilization_metric_names_url }
      format.xml  { head :ok }
    end
  end
  
  # GET /utilization_metric_names/1/version_history
  def version_history
    @utilization_metric_name = UtilizationMetricName.find(params[:id])
    render :action => "version_table", :layout => false
  end
  
  # GET /utilization_metric_names/field_names
  def field_names
    super(UtilizationMetricName)
  end

  # GET /utilization_metric_names/search
  def search
    @utilization_metric_name = UtilizationMetricName.find(:first)
    render :action => 'search'
  end
  
end
