class NodeGroupNodeGroupAssignmentsController < ApplicationController
  # sets the @auth object and @object
  before_filter :get_obj_auth
  before_filter :modelperms

  # GET /node_group_node_group_assignments
  # GET /node_group_node_group_assignments.xml
  def index
    ## BUILD MASTER HASH WITH ALL SUB-PARAMS ##
    allparams = {}
    allparams[:mainmodel] = NodeGroupNodeGroupAssignment
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

  # GET /node_group_node_group_assignments/1
  # GET /node_group_node_group_assignments/1.xml
  def show
    @node_group_node_group_assignment = @object

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @node_group_node_group_assignment.to_xml(:dasherize => false) }
    end
  end

  # GET /node_group_node_group_assignments/new
  def new
    @node_group_node_group_assignment = @object
  end

  # GET /node_group_node_group_assignments/1/edit
  def edit
    @node_group_node_group_assignment = @object
  end

  # POST /node_group_node_group_assignments
  # POST /node_group_node_group_assignments.xml
  def create
    parent = NodeGroup.find(params[:node_group_node_group_assignment][:parent_id])
    return unless filter_perms(@auth,parent,['updater'])
    child = NodeGroup.find(params[:node_group_node_group_assignment][:child_id])
    return unless filter_perms(@auth,child,['updater'])

    @node_group_node_group_assignment = NodeGroupNodeGroupAssignment.new(params[:node_group_node_group_assignment])
    if request.env["HTTP_REFERER"] =~ /http:\/\/.*?\/(\w+)\/(\d+)/
      ref_class = $1.singularize
      ref_id = $2.to_i
    end

    respond_to do |format|
      if @node_group_node_group_assignment.save
        
        format.html { 
          flash[:notice] = 'NodeGroupNodeGroupAssignment was successfully created.'
          redirect_to node_group_node_group_assignment_url(@node_group_node_group_assignment) 
        }
        format.js { 
          if ( (ref_class == 'node_group' && ref_id) && ( ref_obj = ref_class.camelize.constantize.find(ref_id) ) )
            render(:update) { |page|
              page.replace_html 'parent_group_assgns', :partial => 'node_groups/parent_group_assignments', :locals => { :node_group => ref_obj }
              page.replace_html 'child_group_assgns', :partial => 'node_groups/child_group_assignments', :locals => { :node_group => ref_obj }
            }
          end
        }
        format.xml  { head :created, :location => node_group_node_group_assignment_url(@node_group_node_group_assignment) }
      else
        format.html { render :action => "new" }
        format.js   { render(:update) { |page| page.alert(@node_group_node_group_assignment.errors.full_messages) } }
        format.xml  { render :xml => @node_group_node_group_assignment.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /node_group_node_group_assignments/1
  # PUT /node_group_node_group_assignments/1.xml
  def update
    @node_group_node_group_assignment = @object
    @parent_group = @node_group_node_group_assignment.parent_group
    return unless filter_perms(@auth,@parent_group,['updater'])
    @child_group = @node_group_node_group_assignment.child_group
    return unless filter_perms(@auth,@child_group,['updater'])

    respond_to do |format|
      if @node_group_node_group_assignment.update_attributes(params[:node_group_node_group_assignment])
        flash[:notice] = 'NodeGroupNodeGroupAssignment was successfully updated.'
        format.html { redirect_to node_group_node_group_assignment_url(@node_group_node_group_assignment) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @node_group_node_group_assignment.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /node_group_node_group_assignments/1
  # DELETE /node_group_node_group_assignments/1.xml
  def destroy
    @node_group_node_group_assignment = @object
    @parent_group = @node_group_node_group_assignment.parent_group
    return unless filter_perms(@auth,@parent_group,['updater'])
    @child_group = @node_group_node_group_assignment.child_group
    return unless filter_perms(@auth,@child_group,['updater'])
    
    begin
      @node_group_node_group_assignment.destroy
    rescue Exception => destroy_error
      respond_to do |format|
        format.html { 
          flash[:error] = destroy_error.message
          redirect_to node_group_node_group_assignment_url(@node_group_node_group_assignment) and return
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

    # Success!
    respond_to do |format|
      format.html { redirect_to node_group_node_group_assignments_url }
      format.js {
        if ( (ref_class == 'node_group' && ref_id) && ( ref_obj = ref_class.camelize.constantize.find(ref_id) ) )
          render(:update) { |page|
            page.replace_html 'parent_group_assgns', :partial => 'node_groups/parent_group_assignments', :locals => { :node_group => ref_obj }
            page.replace_html 'child_group_assgns', :partial => 'node_groups/child_group_assignments', :locals => { :node_group => ref_obj }
          }
        end
      }
      format.xml  { head :ok }
    end
  end
  
  # GET /node_group_node_group_assignments/1/version_history
  def version_history
    @node_group_node_group_assignment = NodeGroupNodeGroupAssignment.find(params[:id])
    render :action => "version_table", :layout => false
  end
  
end
