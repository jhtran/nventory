class DatacenterNodeRackAssignmentsController < ApplicationController
  # sets the @auth object and @object
  before_filter :get_obj_auth
  before_filter :modelperms

  # GET /datacenter_node_rack_assignments
  # GET /datacenter_node_rack_assignments.xml
  def index
    ## BUILD MASTER HASH WITH ALL SUB-PARAMS ##
    allparams = {}
    allparams[:mainmodel] = DatacenterNodeRackAssignment
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

  # GET /datacenter_node_rack_assignments/1
  # GET /datacenter_node_rack_assignments/1.xml
  def show
    @datacenter_node_rack_assignment = @object

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @datacenter_node_rack_assignment.to_xml(:dasherize => false) }
    end
  end

  # GET /datacenter_node_rack_assignments/new
  def new
    @datacenter_node_rack_assignment = @object
  end

  # GET /datacenter_node_rack_assignments/1/edit
  def edit
    @datacenter_node_rack_assignment = @object
  end

  # POST /datacenter_node_rack_assignments
  # POST /datacenter_node_rack_assignments.xml
  def create
    @datacenter_node_rack_assignment = DatacenterNodeRackAssignment.new(params[:datacenter_node_rack_assignment])
    datacenter = Datacenter.find(params[:datacenter_node_rack_assignment][:datacenter_id])
    return unless filter_perms(@auth,datacenter,'updater')
    node_rack = NodeRack.find(params[:datacenter_node_rack_assignment][:node_rack_id])
    return unless filter_perms(@auth,node_rack,'updater')

    respond_to do |format|
      if @datacenter_node_rack_assignment.save
        
        format.html { 
          flash[:notice] = 'DatacenterNodeRackAssignment was successfully created.'
          redirect_to datacenter_node_rack_assignment_url(@datacenter_node_rack_assignment) 
        }
        format.js { 
          render(:update) { |page| 
            # We expect this AJAX creation to come from one of two places,
            # the datacenter show page or the rack show page. Depending on
            # which we do something slightly different.
            if request.env["HTTP_REFERER"].include? "datacenters"
              page.replace_html 'datacenter_node_rack_assignments', :partial => 'datacenters/node_rack_assignments', :locals => { :datacenter => @datacenter_node_rack_assignment.datacenter }
            elsif request.env["HTTP_REFERER"].include? "node_racks"
              page.replace_html 'datacenter_node_rack_assignments', :partial => 'node_racks/datacenter_assignment', :locals => { :node_rack => @datacenter_node_rack_assignment.node_rack }
            end
          }
        }
        format.xml  { head :created, :location => datacenter_node_rack_assignment_url(@datacenter_node_rack_assignment) }
      else
        format.html { render :action => "new" }
        format.js   { render(:update) { |page| page.alert(@datacenter_node_rack_assignment.errors.full_messages) } }
        format.xml  { render :xml => @datacenter_node_rack_assignment.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /datacenter_node_rack_assignments/1
  # PUT /datacenter_node_rack_assignments/1.xml
  def update
    @datacenter_node_rack_assignment = @object
    datacenter = @datacenter_node_rack_assignment.datacenter
    return unless filter_perms(@auth,datacenter,'updater')
    node_rack = @datacenter_node_rack_assignment.node_rack
    return unless filter_perms(@auth,node_rack,'updater')

    respond_to do |format|
      if @datacenter_node_rack_assignment.update_attributes(params[:datacenter_node_rack_assignment])
        flash[:notice] = 'DatacenterNodeRackAssignment was successfully updated.'
        format.html { redirect_to datacenter_node_rack_assignment_url(@datacenter_node_rack_assignment) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @datacenter_node_rack_assignment.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /datacenter_node_rack_assignments/1
  # DELETE /datacenter_node_rack_assignments/1.xml
  def destroy
    @datacenter_node_rack_assignment = @object
    @datacenter = @datacenter_node_rack_assignment.datacenter
    return unless filter_perms(@auth,@datacenter,'updater')
    @node_rack = @datacenter_node_rack_assignment.node_rack
    return unless filter_perms(@auth,@node_rack,'updater')
    @datacenter_node_rack_assignment.destroy

    respond_to do |format|
      format.html { redirect_to datacenter_node_rack_assignments_url }
      format.js {
#          render(:update) { |page|
#            if request.env["HTTP_REFERER"].include? "datacenters"
#              page.replace_html 'datacenter_node_rack_assignments', :partial => 'datacenters/node_rack_assignments', :locals => { :datacenter => @datacenter_node_rack_assignment.datacenter }
#            elsif request.env["HTTP_REFERER"].include? "node_racks"
#              page.replace_html 'datacenter_node_rack_assignments', :partial => 'node_racks/datacenter_assignment', :locals => { :node_rack => @datacenter_node_rack_assignment.node_rack }
#            end
#          }
        render :text => 'jdsajfldjlfdsjlfdjslal'
      }
      format.xml  { head :ok }
    end
  end
  
  # GET /datacenter_node_rack_assignments/1/version_history
  def version_history
    @datacenter_node_rack_assignment = DatacenterNodeRackAssignment.find(params[:id])
    render :action => "version_table", :layout => false
  end
  
end
