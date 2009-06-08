class LbPoolNodeAssignmentsController < ApplicationController
  # GET /lb_pool_node_assignments
  # GET /lb_pool_node_assignments.xml
  def index
    sort = case params['sort']
           when "assigned_at" then "lb_pool_node_assignments.assigned_at"
           when "assigned_at_reverse" then "lb_pool_node_assignments.assigned_at DESC"
           end
    
    # if a sort was not defined we'll make one default
    if sort.nil?
      params['sort'] = LbPoolNodeAssignment.default_search_attribute
      sort = 'lb_pool_node_assignments.' + LbPoolNodeAssignment.default_search_attribute
    end
    
    # XML doesn't get pagination
    if params[:format] && params[:format] == 'xml'
      @objects = LbPoolNodeAssignment.find(:all, :order => sort)
    else
      @objects = LbPoolNodeAssignment.paginate(:all,
                                              :order => sort,
                                              :page => params[:page])
    end
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @objects.to_xml(:dasherize => false) }
    end
  end

  # GET /lb_pool_node_assignments/1
  # GET /lb_pool_node_assignments/1.xml
  def show
    @lb_pool_node_assignment = LbPoolNodeAssignment.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @lb_pool_node_assignment.to_xml(:dasherize => false) }
    end
  end

  # GET /lb_pool_node_assignments/new
  def new
    @lb_pool_node_assignment = LbPoolNodeAssignment.new
  end

  # GET /lb_pool_node_assignments/1/edit
  def edit
    @lb_pool_node_assignment = LbPoolNodeAssignment.find(params[:id])
  end

  # POST /lb_pool_node_assignments
  # POST /lb_pool_node_assignments.xml
  def create
    @lb_pool_node_assignment = LbPoolNodeAssignment.new(params[:lb_pool_node_assignment])

    respond_to do |format|
      if @lb_pool_node_assignment.save
        
        format.html { 
          flash[:notice] = 'LbPoolNodeAssignment was successfully created.'
          redirect_to lb_pool_node_assignment_url(@lb_pool_node_assignment) 
        }
        format.js { 
          render(:update) { |page| 
            
            page.replace_html 'node_assignments', :partial => 'lb_pools/node_assignments', :locals => { :lb_pool => @lb_pool_node_assignment.lb_pool }
            page.hide 'create_node_assignment'
            page.show 'add_node_assignment_link'
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
    @lb_pool_node_assignment = LbPoolNodeAssignment.find(params[:id])

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
    @lb_pool_node_assignment = LbPoolNodeAssignment.find(params[:id])
    @node = @lb_pool_node_assignment.node
    @lb_pool = @lb_pool_node_assignment.lb_pool
    
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
          
          page.replace_html 'lb_pool_node_assignments', {:partial => 'nodes/node_assignments', :locals => { :node => @node} }
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
