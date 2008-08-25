class DatacenterRackAssignmentsController < ApplicationController
  # GET /datacenter_rack_assignments
  # GET /datacenter_rack_assignments.xml
  def index
    sort = case params['sort']
           when "assigned_at" then "datacenter_rack_assignments.assigned_at"
           when "assigned_at_reverse" then "datacenter_rack_assignments.assigned_at DESC"
           end
    
    # if a sort was not defined we'll make one default
    if sort.nil?
      params['sort'] = DatacenterRackAssignment.default_search_attribute
      sort = 'datacenter_rack_assignments.' + DatacenterRackAssignment.default_search_attribute
    end
    
    # XML doesn't get pagination
    if params[:format] && params[:format] == 'xml'
      @objects = DatacenterRackAssignment.find(:all, :order => sort)
    else
      @objects = DatacenterRackAssignment.paginate(:all,
                                                   :order => sort,
                                                   :page => params[:page])
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @objects.to_xml(:dasherize => false) }
    end
  end

  # GET /datacenter_rack_assignments/1
  # GET /datacenter_rack_assignments/1.xml
  def show
    @datacenter_rack_assignment = DatacenterRackAssignment.find_with_deleted(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @datacenter_rack_assignment.to_xml(:dasherize => false) }
    end
  end

  # GET /datacenter_rack_assignments/new
  def new
    @datacenter_rack_assignment = DatacenterRackAssignment.new
  end

  # GET /datacenter_rack_assignments/1/edit
  def edit
    @datacenter_rack_assignment = DatacenterRackAssignment.find(params[:id])
  end

  # POST /datacenter_rack_assignments
  # POST /datacenter_rack_assignments.xml
  def create
    @datacenter_rack_assignment = DatacenterRackAssignment.new(params[:datacenter_rack_assignment])

    respond_to do |format|
      if @datacenter_rack_assignment.save
        
        format.html { 
          flash[:notice] = 'DatacenterRackAssignment was successfully created.'
          redirect_to datacenter_rack_assignment_url(@datacenter_rack_assignment) 
        }
        format.js { 
          render(:update) { |page| 
            # We expect this AJAX creation to come from one of two places,
            # the datacenter show page or the rack show page. Depending on
            # which we do something slightly different.
            if request.env["HTTP_REFERER"].include? "datacenters"
              page.replace_html 'datacenter_rack_assignments', :partial => 'datacenters/rack_assignments', :locals => { :datacenter => @datacenter_rack_assignment.datacenter }
              page.hide 'create_rack_assignment'
              page.show 'add_rack_assignment_link'
            elsif request.env["HTTP_REFERER"].include? "racks"
              page.replace_html 'datacenter_rack_assignments', :partial => 'racks/datacenter_assignment', :locals => { :rack => @datacenter_rack_assignment.rack }
              page.hide 'create_datacenter_assignment'
            end
          }
        }
        format.xml  { head :created, :location => datacenter_rack_assignment_url(@datacenter_rack_assignment) }
      else
        format.html { render :action => "new" }
        format.js   { render(:update) { |page| page.alert(@datacenter_rack_assignment.errors.full_messages) } }
        format.xml  { render :xml => @datacenter_rack_assignment.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /datacenter_rack_assignments/1
  # PUT /datacenter_rack_assignments/1.xml
  def update
    @datacenter_rack_assignment = DatacenterRackAssignment.find(params[:id])

    respond_to do |format|
      if @datacenter_rack_assignment.update_attributes(params[:datacenter_rack_assignment])
        flash[:notice] = 'DatacenterRackAssignment was successfully updated.'
        format.html { redirect_to datacenter_rack_assignment_url(@datacenter_rack_assignment) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @datacenter_rack_assignment.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /datacenter_rack_assignments/1
  # DELETE /datacenter_rack_assignments/1.xml
  def destroy
    @datacenter_rack_assignment = DatacenterRackAssignment.find(params[:id])
    @datacenter = @datacenter_rack_assignment.datacenter
    @rack = @datacenter_rack_assignment.rack
    @datacenter_rack_assignment.destroy

    respond_to do |format|
      format.html { redirect_to datacenter_rack_assignments_url }
      format.js # will use destroy.js.rjs
      format.xml  { head :ok }
    end
  end
  
  # GET /datacenter_rack_assignments/1/version_history
  def version_history
    @datacenter_rack_assignment = DatacenterRackAssignment.find_with_deleted(params[:id])
    render :action => "version_table", :layout => false
  end
  
end
