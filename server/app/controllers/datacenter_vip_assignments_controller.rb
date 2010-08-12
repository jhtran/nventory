class DatacenterVipAssignmentsController < ApplicationController
  # sets the @auth object and @object
  before_filter :get_obj_auth
  before_filter :modelperms

  # GET /datacenter_vip_assignments
  # GET /datacenter_vip_assignments.xml
  def index
    ## BUILD MASTER HASH WITH ALL SUB-PARAMS ##
    allparams = {}
    allparams[:mainmodel] = DatacenterVipAssignment
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

  # GET /datacenter_vip_assignments/1
  # GET /datacenter_vip_assignments/1.xml
  def show
    @datacenter_vip_assignment = @object

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @datacenter_vip_assignment.to_xml(:dasherize => false) }
    end
  end

  # GET /datacenter_vip_assignments/new
  def new
    @datacenter_vip_assignment = @object
  end

  # GET /datacenter_vip_assignments/1/edit
  def edit
    @datacenter_vip_assignment = @object
  end

  # POST /datacenter_vip_assignments
  # POST /datacenter_vip_assignments.xml
  def create
    @datacenter_vip_assignment = DatacenterVipAssignment.new(params[:datacenter_vip_assignment])
    datacenter = Datacenter.find(params[:datacenter_vip_assignment][:datacenter_id])
    return unless filter_perms(@auth,datacenter,['updater'])
    vip = Vip.find(params[:datacenter_vip_assignment][:vip_id])
    return unless filter_perms(@auth,vip,['updater'])

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
    @datacenter_vip_assignment = @object
    datacenter = @datacenter_vip_assignment.datacenter
    return unless filter_perms(@auth,datacenter,['updater'])
    vip = @datacenter_vip_assignment.vip
    return unless filter_perms(@auth,vip,['updater'])

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
    @datacenter_vip_assignment = @object
    @datacenter = @datacenter_vip_assignment.datacenter
    return unless filter_perms(@auth,@datacenter,['updater'])
    @vip = @datacenter_vip_assignment.vip
    return unless filter_perms(@auth,@vip,['updater'])
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
