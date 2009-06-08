class DatacenterVipAssignmentsController < ApplicationController
  # GET /datacenter_vip_assignments
  # GET /datacenter_vip_assignments.xml
  def index
    sort = case params['sort']
           when "assigned_at" then "datacenter_vip_assignments.assigned_at"
           when "assigned_at_reverse" then "datacenter_vip_assignments.assigned_at DESC"
           end
    
    # if a sort was not defined we'll make one default
    if sort.nil?
      params['sort'] = DatacenterVipAssignment.default_search_attribute
      sort = 'datacenter_vip_assignments.' + DatacenterVipAssignment.default_search_attribute
    end
    
    # XML doesn't get pagination
    if params[:format] && params[:format] == 'xml'
      @objects = DatacenterVipAssignment.find(:all, :order => sort)
    else
      @objects = DatacenterVipAssignment.paginate(:all,
                                                  :order => sort,
                                                  :page => params[:page])
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @objects.to_xml(:dasherize => false) }
    end
  end

  # GET /datacenter_vip_assignments/1
  # GET /datacenter_vip_assignments/1.xml
  def show
    @datacenter_vip_assignment = DatacenterVipAssignment.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @datacenter_vip_assignment.to_xml(:dasherize => false) }
    end
  end

  # GET /datacenter_vip_assignments/new
  def new
    @datacenter_vip_assignment = DatacenterVipAssignment.new
  end

  # GET /datacenter_vip_assignments/1/edit
  def edit
    @datacenter_vip_assignment = DatacenterVipAssignment.find(params[:id])
  end

  # POST /datacenter_vip_assignments
  # POST /datacenter_vip_assignments.xml
  def create
    @datacenter_vip_assignment = DatacenterVipAssignment.new(params[:datacenter_vip_assignment])

    respond_to do |format|
      if @datacenter_vip_assignment.save
        format.html { 
          flash[:notice] = 'Datacenter VIP Assignment was successfully created.'
          redirect_to datacenter_vip_assignment_url(@datacenter_vip_assignment) 
        }
        format.js { 
          render(:update) { |page| 
            page.replace_html 'datacenter_vip_assignments', :partial => 'datacenters/vip_assignments', :locals => { :datacenter => @datacenter_vip_assignment.datacenter }
            page.hide 'create_vip_assignment'
            page.show 'add_vip_assignment_link'
          }
        }
        format.xml  { head :created, :location => datacenter_vip_assignment_url(@datacenter_vip_assignment) }
      else
        format.html { render :action => "new" }
        format.js   { render(:update) { |page| page.alert(@datacenter_vip_assignment.errors.full_messages) } }
        format.xml  { render :xml => @datacenter_vip_assignment.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /datacenter_vip_assignments/1
  # PUT /datacenter_vip_assignments/1.xml
  def update
    @datacenter_vip_assignment = DatacenterVipAssignment.find(params[:id])

    respond_to do |format|
      if @datacenter_vip_assignment.update_attributes(params[:datacenter_vip_assignment])
        flash[:notice] = 'DatacenterVipAssignment was successfully updated.'
        format.html { redirect_to datacenter_vip_assignment_url(@datacenter_vip_assignment) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @datacenter_vip_assignment.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /datacenter_vip_assignments/1
  # DELETE /datacenter_vip_assignments/1.xml
  def destroy
    @datacenter_vip_assignment = DatacenterVipAssignment.find(params[:id])
    @datacenter = @datacenter_vip_assignment.datacenter
    @datacenter_vip_assignment.destroy

    respond_to do |format|
      format.html { redirect_to datacenter_vip_assignments_url }
      format.js {
        render(:update) { |page|
          page.replace_html 'datacenter_vip_assignments', {:partial => 'datacenters/vip_assignments', :locals => { :datacenter => @datacenter} }
        }
      }
      format.xml  { head :ok }
    end
  end
  
  # GET /datacenter_vip_assignments/1/version_history
  def version_history
    @datacenter_vip_assignment = DatacenterVipAssignment.find(params[:id])
    render :action => "version_table", :layout => false
  end
  
end
