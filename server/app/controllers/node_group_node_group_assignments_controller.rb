class NodeGroupNodeGroupAssignmentsController < ApplicationController
  # GET /node_group_node_group_assignments
  # GET /node_group_node_group_assignments.xml
  def index
    sort = case params['sort']
           when "assigned_at" then "node_group_node_group_assignments.assigned_at"
           when "assigned_at_reverse" then "node_group_node_group_assignments.assigned_at DESC"
           end
    
    # if a sort was not defined we'll make one default
    if sort.nil?
      params['sort'] = NodeGroupNodeGroupAssignment.default_search_attribute
      sort = 'node_group_node_group_assignments.' + NodeGroupNodeGroupAssignment.default_search_attribute
    end
    
    # XML doesn't get pagination
    if params[:format] && params[:format] == 'xml'
      @objects = NodeGroupNodeGroupAssignment.find(:all, :order => sort)
    else
      @objects = NodeGroupNodeGroupAssignment.paginate(:all,
                                                   :order => sort,
                                                   :page => params[:page])
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @objects.to_xml(:dasherize => false) }
    end
  end

  # GET /node_group_node_group_assignments/1
  # GET /node_group_node_group_assignments/1.xml
  def show
    @node_group_node_group_assignment = NodeGroupNodeGroupAssignment.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @node_group_node_group_assignment.to_xml(:dasherize => false) }
    end
  end

  # GET /node_group_node_group_assignments/new
  def new
    @node_group_node_group_assignment = NodeGroupNodeGroupAssignment.new
  end

  # GET /node_group_node_group_assignments/1/edit
  def edit
    @node_group_node_group_assignment = NodeGroupNodeGroupAssignment.find(params[:id])
  end

  # POST /node_group_node_group_assignments
  # POST /node_group_node_group_assignments.xml
  def create
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
              page.replace_html 'real_nodes', :partial => 'node_groups/real_node_assignments', :locals => { :node_group => ref_obj }
              page.replace_html 'virtual_nodes', :partial => 'node_groups/virtual_node_assignments', :locals => { :node_group => ref_obj }
              page.replace_html 'child_group_assignments', :partial => 'shared/child_node_group_assignment', :collection => ref_obj.assignments_as_parent
              page.replace_html 'parent_group_assignments', :partial => 'shared/parent_node_group_assignment', :collection => ref_obj.assignments_as_child
 

              page.hide 'create_parent_assignment'
              page.hide 'create_child_assignment'
              page.show 'add_parent_link'
              page.show 'add_child_link'
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
    @node_group_node_group_assignment = NodeGroupNodeGroupAssignment.find(params[:id])

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
    @node_group_node_group_assignment = NodeGroupNodeGroupAssignment.find(params[:id])
    @parent_group = @node_group_node_group_assignment.parent_group
    @child_group = @node_group_node_group_assignment.child_group
    
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
            page.replace_html 'real_nodes', :partial => 'node_groups/real_node_assignments', :locals => { :node_group => ref_obj }
            page.replace_html 'virtual_nodes', :partial => 'node_groups/virtual_node_assignments', :locals => { :node_group => ref_obj }
            page.replace_html 'child_group_assignments', :partial => 'shared/child_node_group_assignment', :collection => ref_obj.assignments_as_parent
            page.replace_html 'parent_group_assignments', :partial => 'shared/parent_node_group_assignment', :collection => ref_obj.assignments_as_child

            page.hide 'create_parent_assignment'
            page.hide 'create_child_assignment'
            page.show 'add_parent_link'
            page.show 'add_child_link'
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
