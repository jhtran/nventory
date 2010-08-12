class VirtualAssignmentsController < ApplicationController
  # sets the @auth object and @object
  before_filter :get_obj_auth
  before_filter :modelperms

  # GET /virtual_assignments
  # GET /virtual_assignments.xml
  def index
    special_joins = {}
    ## BUILD MASTER HASH WITH ALL SUB-PARAMS ##
    allparams = {}
    allparams[:mainmodel] = VirtualAssignment
    allparams[:webparams] = params
    allparams[:special_joins] = special_joins

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

  # GET /virtual_assignments/1
  # GET /virtual_assignments/1.xml
  def show
    @virtual_assignment = @object

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @virtual_assignment.to_xml(:dasherize => false) }
    end
  end

  # GET /virtual_assignments/new
  def new
    @virtual_assignment = @object
  end

  # GET /virtual_assignments/1/edit
  def edit
    @virtual_assignment = @object
  end

  # POST /virtual_assignments
  # POST /virtual_assignments.xml
  def create
    @virtual_assignment = VirtualAssignment.new(params[:virtual_assignment])
    vmhost = Node.find(params[:virtual_assignment][:parent_id])
    return unless filter_perms(@auth,vmhost,['updater'])
    vmguest = Node.find(params[:virtual_assignment][:child_id])
    return unless filter_perms(@auth,vmguest,['updater'])

    respond_to do |format|
      if @virtual_assignment.save
        
        format.html { 
          flash[:notice] = 'VirtualAssignment was successfully created.'
          redirect_to virtual_assignment_url(@virtual_assignment) 
        }
        format.js { 
          render(:update) { |page| 
            
            page.replace_html 'virtual_assignments', :partial => 'nodes/virtual_assignments', :locals => { :node => @virtual_assignment.virtual_host }
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
    @virtual_assignment = @object
    vmhost = @virtual_assignment.parent
    return unless filter_perms(@auth,vmhost,['updater'])
    vmguest = @virtual_assignment.child
    return unless filter_perms(@auth,vmguest,['updater'])

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
    @virtual_assignment = @object
    @virtual_host = @virtual_assignment.virtual_host
    return unless filter_perms(@auth,@virtual_host,['updater'])
    @virtual_guest = @virtual_assignment.virtual_guest
    return unless filter_perms(@auth,@virtual_guest,['updater'])
    
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
          
          page.replace_html 'virtual_assignments', {:partial => 'nodes/virtual_assignments', :locals => { :node => @virtual_host} }
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
