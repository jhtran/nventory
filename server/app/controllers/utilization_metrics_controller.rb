class UtilizationMetricsController < ApplicationController
  # sets the @auth object and @object
  before_filter :get_obj_auth
  before_filter :modelperms

  # GET /utilization_metrics
  # GET /utilization_metrics.xml
  def index
    ## BUILD MASTER HASH WITH ALL SUB-PARAMS ##
    allparams = {}
    allparams[:mainmodel] = UtilizationMetric
    allparams[:webparams] = params
    results = Search.new(allparams).search

    flash[:error] = results[:errors].join('<br />') unless results[:errors].empty?
    includes = results[:includes]
    results[:requested_includes].each_pair{|k,v| includes[k] = v}
    @objects = results[:search_results]

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @objects.to_xml(:dasherize => false) }
    end
  end

  # GET /utilization_metrics/1
  # GET /utilization_metrics/1.xml
  def show
    @utilization_metric = @object

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @utilization_metric.to_xml(:dasherize => false) }
    end
  end

  # GET /utilization_metrics/new
  def new
    @utilization_metric = @object
  end

  # GET /utilization_metrics/1/edit
  def edit
    @utilization_metric = @object
  end

  # POST /utilization_metrics
  # POST /utilization_metrics.xml
  def create
    @utilization_metric = UtilizationMetric.new(params[:utilization_metric])

    respond_to do |format|
      if @utilization_metric.save
        format.html {
          flash[:notice] = 'UtilizationMetric was successfully created.'
          redirect_to utilization_metric_url(@utilization_metric)
        }
        format.js { 
          render(:update) { |page| 
          }
        }
        format.xml  { head :created, :location => utilization_metric_url(@utilization_metric) }
      else
        format.html { render :action => "new" }
        format.js   { render(:update) { |page| page.alert(@utilization_metric.errors.full_messages) } }
        format.xml  { render :xml => @utilization_metric.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /utilization_metrics/1
  # PUT /utilization_metrics/1.xml
  def update
    @utilization_metric = @object

    respond_to do |format|
      if @utilization_metric.update_attributes(params[:utilization_metric])
        flash[:notice] = 'UtilizationMetric was successfully updated.'
        format.html { redirect_to utilization_metric_url(@utilization_metric) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @utilization_metric.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /utilization_metrics/1
  # DELETE /utilization_metrics/1.xml
  def destroy
    @utilization_metric = @object
    @utilization_metric.destroy

    respond_to do |format|
      format.html { redirect_to utilization_metrics_url }
      format.js {
        render(:update) { |page|
        }
      }
      format.xml  { head :ok }
    end
  end
  
  # GET /utilization_metrics/1/version_history
  def version_history
    @utilization_metric = UtilizationMetric.find(params[:id])
    render :action => "version_table", :layout => false
  end

end
