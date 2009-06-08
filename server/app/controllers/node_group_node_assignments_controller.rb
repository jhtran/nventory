class NodeGroupNodeAssignmentsController < ApplicationController
  # GET /node_group_node_assignments
  # GET /node_group_node_assignments.xml
  def index
    sort = case params['sort']
           when "assigned_at" then "node_group_node_assignments.assigned_at"
           when "assigned_at_reverse" then "node_group_node_assignments.assigned_at DESC"
           end
    
    # if a sort was not defined we'll make one default
    if sort.nil?
      params['sort'] = NodeGroupNodeAssignment.default_search_attribute
      sort = 'node_group_node_assignments.' + NodeGroupNodeAssignment.default_search_attribute
    end
    
    # XML doesn't get pagination
    if params[:format] && params[:format] == 'xml'
      @objects = NodeGroupNodeAssignment.find(:all, :order => sort)
    else
      @objects = NodeGroupNodeAssignment.paginate(:all,
                                              :order => sort,
                                              :page => params[:page])
    end
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @objects.to_xml(:dasherize => false) }
    end
  end

  # GET /node_group_node_assignments/1
  # GET /node_group_node_assignments/1.xml
  def show
    @node_group_node_assignment = NodeGroupNodeAssignment.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @node_group_node_assignment.to_xml(:dasherize => false) }
    end
  end

  # GET /node_group_node_assignments/new
  def new
    @node_group_node_assignment = NodeGroupNodeAssignment.new
  end

  # GET /node_group_node_assignments/1/edit
  def edit
    @node_group_node_assignment = NodeGroupNodeAssignment.find(params[:id])
  end

  # POST /node_group_node_assignments
  # POST /node_group_node_assignments.xml
  def create
    @node_group_node_assignment = NodeGroupNodeAssignment.new(params[:node_group_node_assignment])

    respond_to do |format|
      if @node_group_node_assignment.save
        
        format.html { 
          flash[:notice] = 'NodeGroupNodeAssignment was successfully created.'
          redirect_to node_group_node_assignment_url(@node_group_node_assignment) 
        }
        format.js { 
          render(:update) { |page| 
            
            page.replace_html 'node_group_node_assignments', :partial => 'nodes/node_group_assignments', :locals => { :node => @node_group_node_assignment.node }
            page.hide 'create_node_group_assignment'
            page.show 'add_node_group_assignment_link'
          }
        }
        format.xml  { head :created, :location => node_group_node_assignment_url(@node_group_node_assignment) }
      else
        format.html { render :action => "new" }
        format.js   { render(:update) { |page| page.alert(@node_group_node_assignment.errors.full_messages) } }
        format.xml  { render :xml => @node_group_node_assignment.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /node_group_node_assignments/1
  # PUT /node_group_node_assignments/1.xml
  def update
    @node_group_node_assignment = NodeGroupNodeAssignment.find(params[:id])

    respond_to do |format|
      if @node_group_node_assignment.update_attributes(params[:node_group_node_assignment])
        flash[:notice] = 'NodeGroupNodeAssignment was successfully updated.'
        format.html { redirect_to node_group_node_assignment_url(@node_group_node_assignment) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @node_group_node_assignment.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /node_group_node_assignments/1
  # DELETE /node_group_node_assignments/1.xml
  def destroy
    @node_group_node_assignment = NodeGroupNodeAssignment.find(params[:id])
    @node = @node_group_node_assignment.node
    @node_group = @node_group_node_assignment.node_group
    
    begin
      @node_group_node_assignment.destroy
    rescue Exception => destroy_error
      respond_to do |format|
        format.html { 
          flash[:error] = destroy_error.message
          redirect_to node_group_node_assignment_url(@node_group_node_assignment) and return
        }
        format.js   { render(:update) { |page| page.alert(destroy_error.message) } }
        format.xml  { head :error } # FIXME?
      end
      return
    end
    
    # Success!
    respond_to do |format|
      format.html { redirect_to node_group_node_assignments_url }
      format.js {
        render(:update) { |page|
          page.replace_html 'node_group_node_assignments', {:partial => 'nodes/node_group_assignments', :locals => { :node => @node} }
        }
      }
      format.xml  { head :ok }
    end
  end
  
  # GET /node_group_node_assignments/1/version_history
  def version_history
    @node_group_node_assignment = NodeGroupNodeAssignment.find(params[:id])
    render :action => "version_table", :layout => false
  end
  
end
