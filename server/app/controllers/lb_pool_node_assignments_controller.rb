class LbPoolNodeAssignmentsController < ApplicationController
  # sets the @auth object and @object
  before_filter :get_obj_auth
  before_filter :modelperms

  # GET /lb_pool_node_assignments
  # GET /lb_pool_node_assignments.xml
  def index
    ## BUILD MASTER HASH WITH ALL SUB-PARAMS ##
    allparams = {}
    allparams[:mainmodel] = LbPoolNodeAssignment
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

  # GET /lb_pool_node_assignments/1
  # GET /lb_pool_node_assignments/1.xml
  def show
    @lb_pool_node_assignment = @object

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @lb_pool_node_assignment.to_xml(:dasherize => false) }
    end
  end

  # GET /lb_pool_node_assignments/new
  def new
    @lb_pool_node_assignment = @object
  end

  # GET /lb_pool_node_assignments/1/edit
  def edit
    @lb_pool_node_assignment = @object
  end

  # POST /lb_pool_node_assignments
  # POST /lb_pool_node_assignments.xml
  def create
    @lb_pool_node_assignment = LbPoolNodeAssignment.new(params[:lb_pool_node_assignment])
    lb_pool = LbPool.find(params[:lb_pool_node_assignment][:node_group_id])
    return unless filter_perms(@auth,lb_pool,['updater'])
    node = Node.find(params[:lb_pool_node_assignment][:node_id])
    return unless filter_perms(@auth,node,['updater'])

    respond_to do |format|
      if @lb_pool_node_assignment.save
        
        format.html { 
          flash[:notice] = 'LbPoolNodeAssignment was successfully created.'
          redirect_to lb_pool_node_assignment_url(@lb_pool_node_assignment) 
        }
        format.js { 
          render(:update) { |page| 
            page.replace_html 'node_assignments', :partial => 'lb_pools/node_assignments', :locals => { :lb_pool => @lb_pool_node_assignment.lb_pool }
          }
        }
        format.xml  { head :created, :location => lb_pool_node_assignment_url(@lb_pool_node_assignment) }
      else
        format.html { render :action => "new" }
        format.js   { render(:update) { |page| page.alert(@lb_pool_node_assignment.errors.full_messages) } }
        format.xml  { render :xml => @lb_pool_node_assignment.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /lb_pool_node_assignments/1
  # PUT /lb_pool_node_assignments/1.xml
  def update
    @lb_pool_node_assignment = @object
    lb_pool = @lb_pool_node_assignment.lb_pool
    return unless filter_perms(@auth,lb_pool,['updater'])
    node = @lb_pool_node_assignment.node
    return unless filter_perms(@auth,node,['updater'])

    respond_to do |format|
      if @lb_pool_node_assignment.update_attributes(params[:lb_pool_node_assignment])
        flash[:notice] = 'LbPoolNodeAssignment was successfully updated.'
        format.html { redirect_to lb_pool_node_assignment_url(@lb_pool_node_assignment) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @lb_pool_node_assignment.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /lb_pool_node_assignments/1
  # DELETE /lb_pool_node_assignments/1.xml
  def destroy
    @lb_pool_node_assignment = @object
    @node = @lb_pool_node_assignment.node
    return unless filter_perms(@auth,@node,['updater'])
    @lb_pool = @lb_pool_node_assignment.lb_pool
    return unless filter_perms(@auth,@lb_pool,['updater'])
    
    begin
      @lb_pool_node_assignment.destroy
    rescue Exception => destroy_error
      respond_to do |format|
        format.html { 
          flash[:error] = destroy_error.message
          redirect_to lb_pool_node_assignment_url(@lb_pool_node_assignment) and return
        }
        format.js   { render(:update) { |page| page.alert(destroy_error.message) } }
        format.xml  { head :error } # FIXME?
      end
      return
    end
    
    # Success!
    respond_to do |format|
      format.html { redirect_to lb_pool_node_assignments_url }
      format.js {
        render(:update) { |page|
          page.replace_html 'node_assignments', {:partial => 'lb_pools/node_assignments', :locals => { :lb_pool => @lb_pool} }
        }
      }
      format.xml  { head :ok }
    end
  end
  
  # GET /lb_pool_node_assignments/1/version_history
  def version_history
    @lb_pool_node_assignment = LbPoolNodeAssignment.find(params[:id])
    render :action => "version_table", :layout => false
  end
  
end
