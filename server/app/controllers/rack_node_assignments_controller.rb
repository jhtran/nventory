class RackNodeAssignmentsController < ApplicationController
  # GET /rack_node_assignments
  # GET /rack_node_assignments.xml
  def index
    sort = case params['sort']
           when "assigned_at" then "rack_node_assignments.assigned_at"
           when "assigned_at_reverse" then "rack_node_assignments.assigned_at DESC"
           end
    
    # if a sort was not defined we'll make one default
    if sort.nil?
      params['sort'] = RackNodeAssignment.default_search_attribute
      sort = 'rack_node_assignments.' + RackNodeAssignment.default_search_attribute
    end
    
    # XML doesn't get pagination
    if params[:format] && params[:format] == 'xml'
      @objects = RackNodeAssignment.find(:all, :order => sort)
    else
      @objects = RackNodeAssignment.paginate(:all,
                                             :order => sort,
                                             :page => params[:page])
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @objects.to_xml(:dasherize => false) }
    end
  end

  # GET /rack_node_assignments/1
  # GET /rack_node_assignments/1.xml
  def show
    @rack_node_assignment = RackNodeAssignment.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @rack_node_assignment.to_xml(:dasherize => false) }
    end
  end

  # GET /rack_node_assignments/new
  def new
    @rack_node_assignment = RackNodeAssignment.new
  end

  # GET /rack_node_assignments/1/edit
  def edit
    @rack_node_assignment = RackNodeAssignment.find(params[:id])
  end

  # POST /rack_node_assignments
  # POST /rack_node_assignments.xml
  def create
    @rack_node_assignment = RackNodeAssignment.new(params[:rack_node_assignment])

    respond_to do |format|
      if @rack_node_assignment.save
        format.html {
          flash[:notice] = 'RackNodeAssignment was successfully created.'
          redirect_to rack_node_assignment_url(@rack_node_assignment)
        }
        format.js { 
          render(:update) { |page| 
            # We expect this AJAX creation to come from one of two places,
            # the rack show page or the node show page. Depending on
            # which we do something slightly different.
            if request.env["HTTP_REFERER"].include? "racks"
              page.replace_html 'rack_node_assignments', :partial => 'racks/node_assignments', :locals => { :rack => @rack_node_assignment.rack }
              page.hide 'create_node_assignment'
              page.show 'add_node_assignment_link'
            elsif request.env["HTTP_REFERER"].include? "nodes"
              page.replace_html 'rack_node_assignments', :partial => 'nodes/rack_assignment', :locals => { :node => @rack_node_assignment.node }
              page.hide 'create_rack_assignment'
            end
          }
        }
        format.xml  { head :created, :location => rack_node_assignment_url(@rack_node_assignment) }
      else
        format.html { render :action => "new" }
        format.js   { render(:update) { |page| page.alert(@rack_node_assignment.errors.full_messages) } }
        format.xml  { render :xml => @rack_node_assignment.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /rack_node_assignments/1
  # PUT /rack_node_assignments/1.xml
  def update
    @rack_node_assignment = RackNodeAssignment.find(params[:id])

    respond_to do |format|
      if @rack_node_assignment.update_attributes(params[:rack_node_assignment])
        flash[:notice] = 'RackNodeAssignment was successfully updated.'
        format.html { redirect_to rack_node_assignment_url(@rack_node_assignment) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @rack_node_assignment.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /rack_node_assignments/1
  # DELETE /rack_node_assignments/1.xml
  def destroy
    @rack_node_assignment = RackNodeAssignment.find(params[:id])
    @rack = @rack_node_assignment.rack
    @node = @rack_node_assignment.node
    @rack_node_assignment.destroy

    respond_to do |format|
      format.html { redirect_to rack_node_assignments_url }
      format.js {
        render(:update) { |page|
          page.replace_html 'rack_node_assignments', {:partial => 'racks/node_assignments', :locals => { :rack => @rack} }
          # We expect this AJAX deletion to come from one of two places,
          # the rack show page or the node show page. Depending on
          # which we do something slightly different.
          if request.env["HTTP_REFERER"].include? "racks"
            page.replace_html 'rack_node_assignments', :partial => 'racks/node_assignments', :locals => { :rack => @rack }
            page.hide 'create_node_assignment'
            page.show 'add_node_assignment_link'
          elsif request.env["HTTP_REFERER"].include? "nodes"
            page.replace_html 'rack_node_assignments', :partial => 'nodes/rack_assignment', :locals => { :node => @node }
            page.hide 'create_rack_assignment'
            page.show 'add_rack_assignment_link'
          end
        }
      }
      format.xml  { head :ok }
    end
  end
  
  # GET /rack_node_assignments/1/version_history
  def version_history
    @rack_node_assignment = RackNodeAssignment.find(params[:id])
    render :action => "version_table", :layout => false
  end
  
end
