class ReportsController < ApplicationController
  # sets the @auth object and @object
  before_filter :get_obj_auth
  before_filter :modelperms

  def list_reports
    reports = []
    reports << ['Nodes not assigned to racks', :racks_unassigned]
    reports << ['Nodes not updated > 7 days', :have_not_updated]
    reports << ['Unused hardware_profiles', :unused_hardware_profiles]
    reports << ['Nodes OS CPU count != phys CPU count', :conflict_cpucount]
    reports << ['Nodes OS memory != phys memory', :conflict_memorysize]
    reports << ['Nodes Serial # Duplicates', :dup_sns]
    reports << ['Nodes not assigned to apps', :non_app_nodes]
    reports << ['Daily nodes updates', :dailyreg]
    reports << ['Required Tag Membership', :requiredtags]
    return reports
  end
  def racks_unassigned
    # sort param passed from web gui's row header #
    sort = 'nodes.name'
    if (params[:sort] =~ /name_reverse/)
      sort = 'nodes.name DESC'
    end
    @objects = Node.find(:all,:include => {:node_rack_node_assignment=>{:node_rack=>{}}},:conditions => ["node_racks.name is ?",nil], :order => sort).paginate(:page => params[:page])
    respond_to do |format|
      format.html # index.html.erb
    end
  end
  def have_not_updated
    # sort param passed from web gui's row header #
    sort = 'updated_at'
    if (params[:sort] =~ /updated_at_reverse/)
      sort << ' DESC'
    elsif (params[:sort] =~ /name/)
      sort = 'nodes.name'
      sort << ' DESC' if (params[:sort] =~ /name_reverse/)
    end
    @objects = Node.find(:all,:conditions => ['updated_at < ?', (Date.today - 7.days).to_s], :order => sort).paginate(:page => params[:page])
     
    respond_to do |format|
      format.html # index.html.erb
    end
  end
  def unused_hardware_profiles
    unused = []
    sort = 'name'
    if (params[:sort] =~ /name_reverse/)
      sort = 'name DESC'
    end
    allhps = HardwareProfile.find(:all,:include => {:nodes=>{}}, :order => sort)
    allhps.each { |hwp| unused.push(hwp) if hwp.nodes.size < 1  }
    @objects = unused.paginate(:page => params[:page])

    respond_to do |format|
      format.html # index.html.erb
    end
  end
  def conflict_cpucount
    sort = 'nodes.name'
    if (params[:sort] =~ /name_reverse/)
      sort = 'nodes.name DESC'
    end
    @objects = Node.find(:all, :conditions => "os_processor_count != processor_count", :order => sort).paginate(:page => params[:page])
    respond_to do |format|
      format.html # index.html.erb
    end
  end
  def conflict_memorysize
    sort = 'nodes.name'
    if (params[:sort] =~ /name_reverse/)
      sort = 'nodes.name DESC'
    end
    @objects = Node.find(:all, :conditions => "ABS( (physical_memory - os_memory )/os_memory ) > 0.1", :order => sort).paginate(:page => params[:page])
    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def dup_sns
    dups = {}
    dupnodes = []
    allnodes = Node.find(:all , :select => "id,serial_number", :conditions => 'serial_number is not null and serial_number != ""')
    serials = allnodes.collect{|a| a.serial_number.strip}.compact
    while !serials.empty?
      serial = serials.pop
      dups[serial] = 1 unless serials.grep(/#{serial}/i).empty?
    end
    allnodes.each{ |node| dupnodes << node.id if dups[node.serial_number.strip] }
    @objects = Node.find(dupnodes, :order => 'nodes.serial_number').paginate(:page => params[:page])
    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def non_app_nodes
  end

  def assigned_keywords
    returnkeywords
  end

  def delkeyword
    keyword = NgAppKeyword.find(params[:keywordid])
    keyword.destroy if keyword
    returnkeywords
  end

  def addkeyword
    keyword = NgAppKeyword.find(:all, :conditions => ["name like ?","%#{params[:keyword]}%"])
    if params[:keyword] && keyword.nil?
      NgAppKeyword.create({:name => params[:keyword]})
    end
    returnkeywords
  end

  def returnkeywords
    unless params[:hide]
      # list num of nodes of each keyword (node_group name)
      @appresults = {}
      @nodes_size = 0
      @keywords = NgAppKeyword.all
      @keywords.each do |appname|
        ng = NodeGroup.find_by_name(appname.name)
        if ng
          @nodes_size += ng.nodes.size
          @appresults[appname.name] = ng 
        end
      end
    end

    respond_to do |format|
      format.js {
        if params[:hide]
          render(:update) { |page| 
              page.replace_html 'assigned_keywords', :text => '<h3>Assigned Nodes</h3>' 
              page.show 'show_assigned_keywords'
          }
        else
          render(:update) { |page| page.replace_html 'assigned_keywords', :partial => 'assigned_keywords', :locals => {:keywords => @keywords} }
        end
      }
    end
  end

  def unassigned_nodes
    allkeywords = NgAppKeyword.find(:all,:select => 'name').collect(&:name)
    unless params[:hide]
      # all nodes that don't belong to one of the node groups in keywords array
      @unassigned = []
      hwprofiles = HardwareProfile.find(:all,:select => 'id', :conditions => "name like '%proliant%' or name like '%sun-fire%' or name like '%ultra%' or name like '%unknown unknown%'")
      statusid = Status.find_by_name('inservice').id
      if params[:mode] == 'default' || !params[:mode]
        results = Node.find(:all,:select => 'nodes.id,nodes.name,node_groups.name,node_groups.id,status.name,status.id',:include => {:node_groups=>{}, :status=>{}},
                          :conditions => ["status_id = ? and hardware_profile_id in (?)",statusid,hwprofiles], :order => 'nodes.name')
      elsif params[:mode] == 'notin'
        results = Node.find(:all,:select => 'nodes.id,nodes.name,node_groups.name,node_groups.id,status.name,status.id',:include => {:node_groups=>{},:status=>{}},
                          :conditions => ["status_id != ? and hardware_profile_id in (?)",statusid,hwprofiles], :order => 'nodes.name')
      end
      results.each do |node|
        flag = true
        node.node_groups.collect(&:name).each do |name| 
          flag = nil if allkeywords.include?(name) 
        end
        (@unassigned << node) if flag 
      end
      @unassigned.sort!{ |a,b| a.name <=> b.name } 
    end

    respond_to do |format|
      format.js {
        if params[:hide]
          render(:update) { |page| 
              page.replace_html 'unassigned_nodes', :text => '<h3>Nodes Not Assigned</h3>'
              page.show 'show_unassigned_nodes'
          }
        else
          if params[:mode] == 'default' || !params[:mode]
            render(:update) { |page| page.replace_html 'unassigned_nodes', :partial => 'unassigned_nodes', :locals => {:unassigned => @unassigned} }
          elsif params[:mode] == 'notin'
            render(:update) { |page| page.replace_html 'unassigned_nodes', :partial => 'unassigned_nodes_notin', :locals => {:unassigned => @unassigned} }
          end
        end
      }
    end
  end

  def buildrequiredtags
    os = OperatingSystem.find(:all, :select => 'id,name', :conditions => "name like '%linux%' or name like '%unix%' or name like '%windows%' or name like '%solaris%' or name like '%sun%'")
    business_unit_nodes = Node.find(:all, :select => 'nodes.id,nodes.name', :joins => {:node_groups => {:taggings => {:tag => {} } } }, :conditions => 'tags.name = "business_unit"')
    bizids = business_unit_nodes.collect(&:id)
    environment_nodes = Node.find(:all, :select => 'nodes.id,nodes.name',  :joins => {:node_groups => {:taggings => {:tag => {} } } }, :conditions => 'tags.name = "environment"')
    envids = environment_nodes.collect(&:id)
    tier_nodes = Node.find(:all, :select => 'nodes.id,nodes.name', :joins => {:node_groups => {:taggings => {:tag => {} } } }, :conditions => 'tags.name = "tier"')
    tierids = tier_nodes.collect(&:id)
    service_nodes = Node.find(:all, :select => 'nodes.id,nodes.name', :joins => {:node_groups => {:taggings => {:tag => {} } } }, :conditions => 'tags.name = "services"')
    svcids = service_nodes.collect(&:id)

    @goodnodes = Node.find(:all, :conditions => ["id in (?) and id in (?) and id in (?) and id in (?)", bizids, envids, tierids, svcids], :order => :name)
    if @goodnodes.empty?
      @badnodes = Node.find(:all, :joins => {:operating_system =>{}}, :conditions => ["operating_systems.id in (?)", os.collect(&:id)], :order => :name)
    else
      @badnodes = Node.find(:all, :joins => {:operating_system =>{}}, :conditions => ["operating_systems.id in (?) and nodes.id not in (?)", os.collect(&:id), @goodnodes.collect(&:id)], :order => :name)
    end
    @dupnodes = find_dups(business_unit_nodes) + find_dups(environment_nodes) + find_dups(tier_nodes) + find_dups(service_nodes)
  end

  def requiredtags
    buildrequiredtags
  end

  def required_tag_membership
    buildrequiredtags
    @business_unit_ngs = NodeGroup.find(:all,:joins => {:taggings => {:tag =>{}}}, :conditions => 'tags.name = "business_unit"')
    @environment_ngs = NodeGroup.find(:all,:joins => {:taggings => {:tag =>{}}}, :conditions => 'tags.name = "environment"')
    @tier_ngs = NodeGroup.find(:all,:joins => {:taggings => {:tag =>{}}}, :conditions => 'tags.name = "tier"')
    @service_ngs = NodeGroup.find(:all,:joins => {:taggings => {:tag =>{}}}, :conditions => 'tags.name = "services"')

    objects = @goodnodes if params[:mode] == 'met'
    objects = @dupnodes.uniq if params[:mode] == 'dup'
    objects = @badnodes if params[:mode] == 'notmet'

    respond_to do |format|
      format.js {
        render(:update) { |page| 
          page.replace_html params[:mode], :partial => 'required_tag_members', :locals => {:objects => objects.sort{|a,b| a.name<=>b.name}.paginate(:page => params[:page],:order => :name) } 
          page.show "#{params[:mode]}_block"
          page.show "toggle_#{params[:mode]}"
        }
      }
    end
  end

  def find_dups(arr)
    temp = {}
    dups = []
    arr.each{|a| temp[a] ? (dups << a) : (temp[a] = 1)}
    return dups
  end

  def dailyreg
    respond_to do |format|
      format.html { @dailyreg_chart = gen_dailyreg(params[:mode]) }
      format.js {
        @dailyreg_chart = gen_dailyreg(params[:mode])
        render(:update) { |page| page.replace_html 'dailyreg_chart', :partial => 'dailyreg_chart' }
      }
      format.json {
        case params[:graph]
          when 'dailyreg_chart'
            if params[:mode] == 'hourly'
              chart = hourlyreg_chart_method(params[:mode])
            else
              chart = dailyreg_chart_method(params[:mode])
            end
            render :text => chart.to_s
        end
      } # format.json
    end

  end

  def gen_dailyreg(mode=nil)
      open_flash_chart_object(1200,500, url_for( :action => 'dailyreg', :graph => 'dailyreg_chart', :mode => mode, :format => :json ))
  end
  
  def dailyreg_chart_method(mode=nil)
    # default settings set for 30days
    if mode.nil?
      settings = {:counter => 30, :increment => 1}
    else
      if mode == '3months'
        settings = {:counter => 90, :increment => 3}
      elsif mode == '6months'
        settings = {:counter => 182, :increment => 6}
      elsif mode == '1year'
        settings = {:counter => 365, :increment => 12}
      else
        settings = {:counter => 30, :increment => 1}
      end
    end

    data = {}
    data[:values] = []
    days = []

    # Create datapoints for the past 30 days and keep them in array so that their order is retained
    counter = settings[:counter]
    while counter > 0
      day = counter.days.ago.day
      month = counter.days.ago.month
      year = counter.days.ago.year
      days << "#{month.to_s}/#{day.to_s}"
      startdate = Date.new(year,month,day).strftime("%Y-%m-%d 00:00:00")
      enddate = Date.new(year,month,day).strftime("%Y-%m-%d 23:59:59")
      data[:values] << Audit.count(:all, :conditions => ["auditable_type = 'Node' and user_id = 2 and action = 'update' and (created_at between ? and ?)", startdate, enddate])
      counter -= settings[:increment]
    end

    # Create Graph
    title = Title.new("Number of Nodes Updates")
    title.set_style('{font-size: 20px; color: #778877}')
    line = Line.new
    line.text = "updates"
    line.set_values(data[:values])
    y = YAxis.new
    y.set_range(0,data[:values].sort.last,data[:values].sort.last/20)
    x = XAxis.new
    x.set_labels(days)

    chart = OpenFlashChart.new
    chart.set_title(title)
    chart.add_element(line)
    chart.x_axis = x
    chart.y_axis = y

    return chart
  end

  def hourlyreg_chart_method(mode=nil)
    # mode param not used - ignore it
    data = {}
    data[:values] = []
    hours = []

    # Create datapoints for the past 30 days and keep them in array so that their order is retained
    counter = 24
    while counter >= 1
      hour = counter.hours.ago.hour
      date = DateTime.now
      hours << "#{hour}:00"
      startdate = date.strftime("%Y-%m-%d #{hour}:00:00")
      enddate = date.strftime("%Y-%m-%d #{hour}:59:59")
      data[:values] << Audit.count(:all, :conditions => ["auditable_type = 'Node' and user_id = 2 and action = 'update' and (created_at between ? and ?)", startdate, enddate])
      counter -= 1
    end

    # Create Graph
    title = Title.new("Number of Nodes Updates")
    title.set_style('{font-size: 20px; color: #778877}')
    line = Line.new
    line.text = "updates"
    line.set_values(data[:values])
    y = YAxis.new
    y.set_range(0,data[:values].sort.last,data[:values].sort.last/20)
    x = XAxis.new
    x.set_labels(hours)

    chart = OpenFlashChart.new
    chart.set_title(title)
    chart.add_element(line)
    chart.x_axis = x
    chart.y_axis = y

    return chart
  end

end
