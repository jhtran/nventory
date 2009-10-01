class ReportsController < ApplicationController
  def list_reports
    reports = []
    reports << ['Nodes unassigned to a rack', :racks_unassigned]
    reports << ['Nodes not updated > 7 days', :have_not_updated]
    reports << ['Unused hardware_profiles', :unused_hardware_profiles]
    reports << ['Nodes which OS CPU count != physical CPU count', :conflict_cpucount]
    reports << ['Nodes which OS memory != physical memory', :conflict_memorysize]
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
end
