class ReportsController < ApplicationController
  def racks_unassigned
    # sort param passed from web gui's row header #
    sort = 'nodes.name'
    if (params[:sort] =~ /name_reverse/)
      sort = 'nodes.name DESC'
    end
    @objects = Node.find(:all,:include => {:rack_node_assignment=>{:rack=>{}}},:conditions => ["racks.name is ?",nil], :order => sort).paginate(:page => params[:page])
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
end
