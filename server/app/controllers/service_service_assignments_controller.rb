class ServiceServiceAssignmentsController < ApplicationController
  # sets the @auth object and @object
  before_filter :get_obj_auth
  before_filter :modelperms

  # GET /service_service_assignments
  # GET /service_service_assignments.xml
  def index
    ## BUILD MASTER HASH WITH ALL SUB-PARAMS ##
    allparams = {}
    allparams[:mainmodel] = ServiceServiceAssignment
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

  # GET /service_service_assignments/1
  # GET /service_service_assignments/1.xml
  def show
    @service_service_assignment = @object

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @service_service_assignment.to_xml(:dasherize => false) }
    end
  end

  # GET /service_service_assignments/new
  def new
    @service_service_assignment = @object
  end

  # GET /service_service_assignments/1/edit
  def edit
    @service_service_assignment = @object
  end

  # POST /service_service_assignments
  # POST /service_service_assignments.xml
  def create
    @service_service_assignment = ServiceServiceAssignment.new(params[:service_service_assignment])
    child = Service.find(params[:service_service_assignment][:child_id])
    return unless filter_perms(@auth,child,['updater'])
    parent = Service.find(params[:service_service_assignment][:parent_id])
    return unless filter_perms(@auth,parent,['updater'])

    if request.env["HTTP_REFERER"] =~ /http:\/\/.*?\/(\w+)\/(\d+)/
      ref_class = $1.singularize
      ref_id = $2.to_i
    end
    respond_to do |format|
      if @service_service_assignment.save
        format.html { 
          flash[:notice] = 'ServiceServiceAssignment was successfully created.'
          redirect_to service_service_assignment_url(@service_service_assignment) 
        }
        format.js {
          if ( (ref_class == 'service' && ref_id) && ( ref_obj = ref_class.camelize.constantize.find(ref_id) ) )
            render(:update) { |page|
              page.replace_html 'parent_service_assgns', :partial => 'services/parent_service_assignments', :locals => { :service => ref_obj }
              page.replace_html 'child_service_assgns', :partial => 'services/child_service_assignments', :locals => { :service => ref_obj }
            }
          end
        }
        format.xml  { head :created, :location => service_service_assignment_url(@service_service_assignment) }
      else
        format.html { render :action => "new" }
        format.js   { render(:update) { |page| page.alert(@service_service_assignment.errors.full_messages) } }
        format.xml  { render :xml => @service_service_assignment.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /service_service_assignments/1
  # PUT /service_service_assignments/1.xml
  def update
    @service_service_assignment = @object
    child = @service_service_assignment.child_service
    return unless filter_perms(@auth,child,['updater'])
    parent = @service_service_assignment.parent_service
    return unless filter_perms(@auth,parent,['updater'])

    respond_to do |format|
      if @service_service_assignment.update_attributes(params[:service_service_assignment])
        flash[:notice] = 'ServiceServiceAssignment was successfully updated.'
        format.html { redirect_to service_service_assignment_url(@service_service_assignment) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @service_service_assignment.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /service_service_assignments/1
  # DELETE /service_service_assignments/1.xml
  def destroy
    @service_service_assignment = @object
    @parent_service = @service_service_assignment.parent_service
    return unless filter_perms(@auth,@parent_service,['updater'])
    @child_service = @service_service_assignment.child_service
    return unless filter_perms(@auth,@child_service,['updater'])
    
    begin
      @service_service_assignment.destroy
    rescue Exception => destroy_error
      respond_to do |format|
        format.html { 
          flash[:error] = destroy_error.message
          redirect_to service_service_assignment_url(@service_service_assignment) and return
        }
        format.js   { render(:update) { |page| page.alert(destroy_error.message) } }
        format.xml  { head :error } # FIXME?
      end
      return
    end
    
    # Success!
    if request.env["HTTP_REFERER"] =~ /http:\/\/.*?\/(\w+)\/(\d+)/
      ref_class = $1.singularize
      ref_id = $2.to_i
    end
    respond_to do |format|
      format.html { redirect_to service_service_assignments_url }
      format.js {
        if ( (ref_class == 'service' && ref_id) && ( ref_obj = ref_class.camelize.constantize.find(ref_id) ) )
          render(:update) { |page|
            page.replace_html 'parent_service_assgns', :partial => 'services/parent_service_assignments', :locals => { :service => ref_obj }
            page.replace_html 'child_service_assgns', :partial => 'services/child_service_assignments', :locals => { :service => ref_obj }
          }
        end
      }
      format.xml  { head :ok }
    end
  end
  
  # GET /service_service_assignments/1/version_history
  def version_history
    @service_service_assignment = ServiceServiceAssignment.find(params[:id])
    render :action => "version_table", :layout => false
  end
  
end
