class UtilizationMetricsByNodeGroupsController < ApplicationController
  # sets the @auth object and @object
  before_filter :get_obj_auth
  before_filter :modelperms

  # GET /utilization_metrics_by_node_group
  # GET /utilization_metrics_by_node_group.xml
  def index
    ## BUILD MASTER HASH WITH ALL SUB-PARAMS ##
    allparams = {}
    allparams[:mainmodel] = UtilizationMetricsByNodeGroup
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

  # GET /utilization_metrics_by_node_group/1
  # GET /utilization_metrics_by_node_group/1.xml
  def show
    @utilization_metrics_by_node_group = @object

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @utilization_metrics_by_node_group.to_xml(:dasherize => false) }
    end
  end

  # GET /utilization_metrics_by_node_group/new
  def new
    @utilization_metrics_by_node_group = @object
  end

  # GET /utilization_metrics_by_node_group/1/edit
  def edit
    @utilization_metrics_by_node_group = @object
  end

  # POST /utilization_metrics_by_node_group
  # POST /utilization_metrics_by_node_group.xml
  def create
    @utilization_metrics_by_node_group = UtilizationMetricsByNodeGroup.new(params[:utilization_metrics_by_node_group])

    respond_to do |format|
      if @utilization_metrics_by_node_group.save
        format.html {
          flash[:notice] = 'UtilizationMetricsByNodeGroup was successfully created.'
          redirect_to utilization_metrics_by_node_group_url(@utilization_metrics_by_node_group)
        }
        format.js { 
          render(:update) { |page| 
          }
        }
        format.xml  { head :created, :location => utilization_metrics_by_node_group_url(@utilization_metrics_by_node_group) }
      else
        format.html { render :action => "new" }
        format.js   { render(:update) { |page| page.alert(@utilization_metrics_by_node_group.errors.full_messages) } }
        format.xml  { render :xml => @utilization_metrics_by_node_group.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /utilization_metrics_by_node_group/1
  # PUT /utilization_metrics_by_node_group/1.xml
  def update
    @utilization_metrics_by_node_group = @object

    respond_to do |format|
      if @utilization_metrics_by_node_group.update_attributes(params[:utilization_metric])
        flash[:notice] = 'UtilizationMetricsByNodeGroup was successfully updated.'
        format.html { redirect_to utilization_metrics_by_node_group_url(@utilization_metrics_by_node_group) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @utilization_metrics_by_node_group.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /utilization_metrics_by_node_group/1
  # DELETE /utilization_metrics_by_node_group/1.xml
  def destroy
    @utilization_metrics_by_node_group = @object
    @utilization_metrics_by_node_group.destroy

    respond_to do |format|
      format.html { redirect_to utilization_metrics_by_node_group_url }
      format.js {
        render(:update) { |page|
        }
      }
      format.xml  { head :ok }
    end
  end
  
  # GET /utilization_metrics_by_node_group/1/version_history
  def version_history
    @utilization_metrics_by_node_group = UtilizationMetricsByNodeGroup.find(params[:id])
    render :action => "version_table", :layout => false
  end
  
  def process_node_group_metrics(daystart=1,dayend=1)
    if daystart > dayend
      puts "You specified begin date (# days ago) a higher number than the end date"
      return false
    end
    ## Purge all node metric entries older than 90 days
    old_metrics = UtilizationMetric.find(:all, :conditions => ["assigned_at < ?", 31.days.ago])
    old_metrics.each{|om| om.destroy}
    ## End purge
    t = Time.new
    stamp = t.strftime("%m%d%Y")
    logf = File.open("/tmp/process_node_group_metrics.#{stamp}",'w')
    (daystart..dayend).each do |day|
      logf.write "***** Processing #{day.days.ago} *****\n"
      results = UtilizationMetricsByNodeGroup.count(:all,:conditions => ["assigned_at like ?", "%#{day.days.ago.strftime("%Y-%m-%d")}%"])
      # if results aren't empty, that means we've already processed for that day!
      if results > 0
        puts "UtilizationMetricsByNodeGroup already exists for that day #{day.days.ago}"
        next
      end
      NodeGroup.all.each do |ng|
        ng_prcnt_cpu = []
        nodes_count = 0
        ng.nodes.each do |node|
          if node.virtual_guest?
 	    logf.write "Skipping #{node.name} - is Virtual Guest\n"
	    next
	  end
          nd_prcnt_cpu = []
          metrics = UtilizationMetric.find(:all, 
              :include => {:utilization_metric_name => {}, :node => {}},
              :conditions => ["node_id = ? and utilization_metric_names.name = ? and assigned_at like ?",
                 node.id, 'percent_cpu', "%#{day.days.ago.strftime("%Y-%m-%d")}%"])
          nodes_count += 1 unless metrics.empty?
          metrics.each do |metric|
            metric.value.kind_of?(Integer) ? (nd_prcnt_cpu << metric.value) : (nd_prcnt_cpu << metric.value.to_i)
          end # metrics.each do |metric|
          ( nd_prcnt_cpu.size == 0 || nd_prcnt_cpu.sum == 0) ? next : ( ng_prcnt_cpu << nd_prcnt_cpu.sum / nd_prcnt_cpu.size )
        end # ng.nodes.each do |ng|
        # The sum and | or size should never be 0.  If so skip the node group metric creation
        (ng_prcnt_cpu.size == 0 || ng_prcnt_cpu.sum == 0) ? next : (ng_avg = ng_prcnt_cpu.sum / ng_prcnt_cpu.size) 
        logf.write "#{ng.name}: #{ng_avg.to_s}\n"
        metric_obj = UtilizationMetricName.find_by_name('percent_cpu')
        UtilizationMetricsByNodeGroup.create( 
          { :node_group_id => ng.id,
            :utilization_metric_name_id => metric_obj.id,
            :assigned_at => day.days.ago,
            :node_count => nodes_count,
            :value => ng_avg })
      end # NodeGroup.all.each do |ng|
    end # (daystart..dayend).each do |day|
    logf.close
  end
  
end
