class NodeRackNodeAssignmentsController < ApplicationController
  # GET /node_rack_node_assignments
  # GET /node_rack_node_assignments.xml
  def index
    sort = case params['sort']
           when "assigned_at" then "node_rack_node_assignments.assigned_at"
           when "assigned_at_reverse" then "node_rack_node_assignments.assigned_at DESC"
           end
    
    # if a sort was not defined we'll make one default
    if sort.nil?
      params['sort'] = NodeRackNodeAssignment.default_search_attribute
      sort = 'node_rack_node_assignments.' + NodeRackNodeAssignment.default_search_attribute
    end
    
    # XML doesn't get pagination
    if params[:format] && params[:format] == 'xml'
      @objects = NodeRackNodeAssignment.find(:all, :order => sort)
    else
      @objects = NodeRackNodeAssignment.paginate(:all,
                                             :order => sort,
                                             :page => params[:page])
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @objects.to_xml(:dasherize => false) }
    end
  end

  # GET /node_rack_node_assignments/1
  # GET /node_rack_node_assignments/1.xml
  def show
    @node_rack_node_assignment = NodeRackNodeAssignment.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @node_rack_node_assignment.to_xml(:dasherize => false) }
    end
  end

  # GET /node_rack_node_assignments/new
  def new
    @node_rack_node_assignment = NodeRackNodeAssignment.new
  end

  # GET /node_rack_node_assignments/1/edit
  def edit
    @node_rack_node_assignment = NodeRackNodeAssignment.find(params[:id])
  end

  # POST /node_rack_node_assignments
  # POST /node_rack_node_assignments.xml
  def create
    @node_rack_node_assignment = NodeRackNodeAssignment.new(params[:node_rack_node_assignment])

    respond_to do |format|
      if @node_rack_node_assignment.save
        format.html {
          flash[:notice] = 'NodeRackNodeAssignment was successfully created.'
          redirect_to node_rack_node_assignment_url(@node_rack_node_assignment)
        }
        format.js { 
          render(:update) { |page| 
            # We expect this AJAX creation to come from one of two places,
            # the rack show page or the node show page. Depending on
            # which we do something slightly different.
            if request.env["HTTP_REFERER"].include? "node_racks"
              page.replace_html 'node_rack_node_assignments', :partial => 'node_racks/node_assignments', :locals => { :node_rack => @node_rack_node_assignment.node_rack }
              page.hide 'create_node_rack_assignment'
              page.show 'add_node_rack_assignment_link'
            elsif request.env["HTTP_REFERER"].include? "nodes"
              page.replace_html 'node_rack_node_assignments', :partial => 'nodes/node_rack_assignment', :locals => { :node => @node_rack_node_assignment.node }
              page.hide 'create_node_rack_assignment'
            end
          }
        }
        format.xml  { head :created, :location => node_rack_node_assignment_url(@node_rack_node_assignment) }
      else
        format.html { render :action => "new" }
        format.js   { render(:update) { |page| page.alert(@node_rack_node_assignment.errors.full_messages) } }
        format.xml  { render :xml => @node_rack_node_assignment.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /node_rack_node_assignments/1
  # PUT /node_rack_node_assignments/1.xml
  def update
    @node_rack_node_assignment = NodeRackNodeAssignment.find(params[:id])

    respond_to do |format|
      if @node_rack_node_assignment.update_attributes(params[:node_rack_node_assignment])
        flash[:notice] = 'NodeRackNodeAssignment was successfully updated.'
        format.html { redirect_to node_rack_node_assignment_url(@node_rack_node_assignment) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @node_rack_node_assignment.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /node_rack_node_assignments/1
  # DELETE /node_rack_node_assignments/1.xml
  def destroy
    @node_rack_node_assignment = NodeRackNodeAssignment.find(params[:id])
    @node_rack = @node_rack_node_assignment.node_rack
    @node = @node_rack_node_assignment.node
    @node_rack_node_assignment.destroy

    respond_to do |format|
      format.html { redirect_to node_rack_node_assignments_url }
      format.js {
        render(:update) { |page|
          page.replace_html 'node_rack_node_assignments', {:partial => 'node_racks/node_assignments', :locals => { :node_rack => @node_rack} }
          # We expect this AJAX deletion to come from one of two places,
          # the rack show page or the node show page. Depending on
          # which we do something slightly different.
          if request.env["HTTP_REFERER"].include? "node_racks"
            page.replace_html 'node_rack_node_assignments', :partial => 'node_racks/node_assignments', :locals => { :node_rack => @node_rack }
            page.hide 'create_node_rack_assignment'
            page.show 'add_node_rack_assignment_link'
          elsif request.env["HTTP_REFERER"].include? "nodes"
            page.replace_html 'node_rack_node_assignments', :partial => 'nodes/node_rack_assignment', :locals => { :node => @node }
            page.hide 'create_node_rack_assignment'
            page.show 'add_node_rack_assignment_link'
          end
        }
      }
      format.xml  { head :ok }
    end
  end
  
  # GET /node_rack_node_assignments/1/version_history
  def version_history
    @node_rack_node_assignment = NodeRackNodeAssignment.find(params[:id])
    render :action => "version_table", :layout => false
  end
  
end
