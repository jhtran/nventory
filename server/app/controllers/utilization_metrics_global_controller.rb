class UtilizationMetricsGlobalController < ApplicationController
  # sets the @auth object and @object
  before_filter :get_obj_auth
  before_filter :modelperms

  # GET /utilization_metrics_global
  # GET /utilization_metrics_global.xml
  def index
    ## BUILD MASTER HASH WITH ALL SUB-PARAMS ##
    allparams = {}
    allparams[:mainmodel] = UtilizationMetricsGlobal
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

  # GET /utilization_metrics_global/1
  # GET /utilization_metrics_global/1.xml
  def show
    @utilization_metrics_global = @object

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @utilization_metrics_global.to_xml(:dasherize => false) }
    end
  end

  # GET /utilization_metrics_global/new
  def new
    @utilization_metrics_global = @object
  end

  # GET /utilization_metrics_global/1/edit
  def edit
    @utilization_metrics_global = @object
  end

  # POST /utilization_metrics_global
  # POST /utilization_metrics_global.xml
  def create
    @utilization_metrics_global = UtilizationMetricsGlobal.new(params[:utilization_metrics_global])

    respond_to do |format|
      if @utilization_metrics_global.save
        format.html {
          flash[:notice] = 'UtilizationMetricsGlobal was successfully created.'
          redirect_to utilization_metrics_global_url(@utilization_metrics_global)
        }
        format.js { 
          render(:update) { |page| 
          }
        }
        format.xml  { head :created, :location => utilization_metrics_global_url(@utilization_metrics_global) }
      else
        format.html { render :action => "new" }
        format.js   { render(:update) { |page| page.alert(@utilization_metrics_global.errors.full_messages) } }
        format.xml  { render :xml => @utilization_metrics_global.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /utilization_metrics_global/1
  # PUT /utilization_metrics_global/1.xml
  def update
    @utilization_metrics_global = @object

    respond_to do |format|
      if @utilization_metrics_global.update_attributes(params[:utilization_metric])
        flash[:notice] = 'UtilizationMetricsGlobal was successfully updated.'
        format.html { redirect_to utilization_metrics_global_url(@utilization_metrics_global) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @utilization_metrics_global.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /utilization_metrics_global/1
  # DELETE /utilization_metrics_global/1.xml
  def destroy
    @utilization_metrics_global = @object
    @utilization_metrics_global.destroy

    respond_to do |format|
      format.html { redirect_to utilization_metrics_global_url }
      format.js {
        render(:update) { |page|
        }
      }
      format.xml  { head :ok }
    end
  end
  
  # GET /utilization_metrics_global/1/version_history
  def version_history
    @utilization_metrics_global = UtilizationMetricsGlobal.find(params[:id])
    render :action => "version_table", :layout => false
  end
  
  def process_global_metrics(daystart=1,dayend=1)
    t = Time.new
    stamp = t.strftime("%m%d%Y")
    logf = File.open("/tmp/process_global_metrics.#{stamp}",'w')
    (daystart..dayend).each do |day|
      logf.write "Processing date: #{day.days.ago}\n"
      puts "Processing date: #{day.days.ago}\n"
      results = UtilizationMetricsGlobal.count(:all,:conditions => ["assigned_at like ?", "%#{day.days.ago.strftime("%Y-%m-%d")}%"])
      # if results aren't empty, that means we've already processed for that day!
      if results > 0
        puts "UtilizationMetricsGlobal already exists for that day #{day.days.ago}"
        next
      end

      global = {}
      UtilizationMetricName.find(:all, :select => "DISTINCT name").each{ |metric| global[metric.name] = [] }
      metrics = UtilizationMetricsByNodeGroup.find(:all, 
          :conditions => ["assigned_at like ?", "%#{day.days.ago.strftime("%Y-%m-%d")}%"])
      node_count = UtilizationMetric.count(:all, :select => "DISTINCT node_id",
          :conditions => ["assigned_at like ?", "%#{day.days.ago.strftime("%Y-%m-%d")}%"])
      metrics.each { |umg| 
        global[umg.utilization_metric_name.name] <<  umg.value.to_i 
      }
      global.keys.each do |key|
        (global[key].size.to_i == 0 || global[key].sum.to_i == 0) ? next : (global_avg = global[key].sum.to_i / global[key].size.to_i)
        metric_obj = UtilizationMetricName.find_by_name(key)
	logf.write "#{key}: #{global_avg.to_s}\n"
        UtilizationMetricsGlobal.create( 
          { :utilization_metric_name => metric_obj,
            :assigned_at => day.days.ago,
            :node_count => node_count,
            :value => global_avg })
      end # global.keys.each do |key|
    end # (daystart..dayend).each do |day|
    logf.close
  end
  
end
