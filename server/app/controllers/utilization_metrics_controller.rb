class UtilizationMetricsController < ApplicationController
  # GET /utilization_metrics
  # GET /utilization_metrics.xml
  def index
    sort = case params['sort']
           when "assigned_at" then "utilization_metrics.assigned_at"
           when "assigned_at_reverse" then "utilization_metrics.assigned_at DESC"
           end
    
    # if a sort was not defined we'll make one default
    if sort.nil?
      params['sort'] = UtilizationMetric.default_search_attribute
      sort = 'utilization_metrics.' + UtilizationMetric.default_search_attribute
    end
    
    # XML doesn't get pagination
    if params[:format] && params[:format] == 'xml'
      @objects = UtilizationMetric.find(:all, :order => sort)
    else
      @objects = UtilizationMetric.paginate(:all,
                                             :order => sort,
                                             :page => params[:page])
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @objects.to_xml(:dasherize => false) }
    end
  end

  # GET /utilization_metrics/1
  # GET /utilization_metrics/1.xml
  def show
    @utilization_metric = UtilizationMetric.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @utilization_metric.to_xml(:dasherize => false) }
    end
  end

  # GET /utilization_metrics/new
  def new
    @utilization_metric = UtilizationMetric.new
  end

  # GET /utilization_metrics/1/edit
  def edit
    @utilization_metric = UtilizationMetric.find(params[:id])
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
    @utilization_metric = UtilizationMetric.find(params[:id])

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
    @utilization_metric = UtilizationMetric.find(params[:id])
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
