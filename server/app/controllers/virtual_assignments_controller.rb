class VirtualAssignmentsController < ApplicationController
  # GET /virtual_assignments
  # GET /virtual_assignments.xml
  def index
    sort = case params['sort']
           when "assigned_at" then "virtual_assignments.assigned_at"
           when "assigned_at_reverse" then "virtual_assignments.assigned_at DESC"
           end
    
    # if a sort was not defined we'll make one default
    if sort.nil?
      params['sort'] = VirtualAssignment.default_search_attribute
      sort = 'virtual_assignments.' + VirtualAssignment.default_search_attribute
    end
    
    # XML doesn't get pagination
    if params[:format] && params[:format] == 'xml'
      @objects = VirtualAssignment.find(:all, :order => sort)
    else
      @objects = VirtualAssignment.paginate(:all,
                                                   :order => sort,
                                                   :page => params[:page])
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @objects.to_xml(:dasherize => false) }
    end
  end

  # GET /virtual_assignments/1
  # GET /virtual_assignments/1.xml
  def show
    @virtual_assignment = VirtualAssignment.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @virtual_assignment.to_xml(:dasherize => false) }
    end
  end

  # GET /virtual_assignments/new
  def new
    @virtual_assignment = VirtualAssignment.new
  end

  # GET /virtual_assignments/1/edit
  def edit
    @virtual_assignment = VirtualAssignment.find(params[:id])
  end

  # POST /virtual_assignments
  # POST /virtual_assignments.xml
  def create
    @virtual_assignment = VirtualAssignment.new(params[:virtual_assignment])

    respond_to do |format|
      if @virtual_assignment.save
        
        format.html { 
          flash[:notice] = 'VirtualAssignment was successfully created.'
          redirect_to virtual_assignment_url(@virtual_assignment) 
        }
        format.js { 
          render(:update) { |page| 
            
            page.replace_html 'virtual_assignments', :partial => 'nodes/virtual_assignments', :locals => { :node => @virtual_assignment.node }
            page.hide 'create_virtual_assignment'
            page.show 'add_virtual_assignment_link'
          }
        }
        format.xml  { head :created, :location => virtual_assignment_url(@virtual_assignment) }
      else
        format.html { render :action => "new" }
        format.js   { render(:update) { |page| page.alert(@virtual_assignment.errors.full_messages) } }
        format.xml  { render :xml => @virtual_assignment.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /virtual_assignments/1
  # PUT /virtual_assignments/1.xml
  def update
    @virtual_assignment = VirtualAssignment.find(params[:id])

    respond_to do |format|
      if @virtual_assignment.update_attributes(params[:virtual_assignment])
        flash[:notice] = 'VirtualAssignment was successfully updated.'
        format.html { redirect_to virtual_assignment_url(@virtual_assignment) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @virtual_assignment.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /virtual_assignments/1
  # DELETE /virtual_assignments/1.xml
  def destroy
    @virtual_assignment = VirtualAssignment.find(params[:id])
    @virtual_host = @virtual_assignment.virtual_host
    @virtual_guest = @virtual_assignment.virtual_guest
    
    begin
      @virtual_assignment.destroy
    rescue Exception => destroy_error
      respond_to do |format|
        format.html { 
          flash[:error] = destroy_error.message
          redirect_to virtual_assignment_url(@virtual_assignment) and return
        }
        format.js   { render(:update) { |page| page.alert(destroy_error.message) } }
        format.xml  { head :error } # FIXME?
      end
      return
    end
    
    # Success!
    respond_to do |format|
      format.html { redirect_to virtual_assignments_url }
      format.js {
        render(:update) { |page|
          
          page.replace_html 'virtual_assignments', {:partial => 'nodes/virtual_assignments', :locals => { :node => @node} }
        }
      }
      format.xml  { head :ok }
    end
  end
  
  # GET /virtual_assignments/1/version_history
  def version_history
    @virtual_assignment = VirtualAssignment.find(params[:id])
    render :action => "version_table", :layout => false
  end
  
end
