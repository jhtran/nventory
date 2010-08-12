class NodeRackNodeAssignmentsController < ApplicationController
  # sets the @auth object and @object
  before_filter :get_obj_auth
  before_filter :modelperms

  # GET /node_rack_node_assignments
  # GET /node_rack_node_assignments.xml
  def index
    ## BUILD MASTER HASH WITH ALL SUB-PARAMS ##
    allparams = {}
    allparams[:mainmodel] = NodeRackNodeAssignment
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

  # GET /node_rack_node_assignments/1
  # GET /node_rack_node_assignments/1.xml
  def show
    @node_rack_node_assignment = @object

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @node_rack_node_assignment.to_xml(:dasherize => false) }
    end
  end

  # GET /node_rack_node_assignments/new
  def new
    @node_rack_node_assignment = @object
  end

  # GET /node_rack_node_assignments/1/edit
  def edit
    @node_rack_node_assignment = @object
  end

  # POST /node_rack_node_assignments
  # POST /node_rack_node_assignments.xml
  def create
    node_rack = NodeRack.find(params[:node_rack_node_assignment][:node_rack_id])
    return unless filter_perms(@auth,node_rack,'updater')
    node = Node.find(params[:node_rack_node_assignment][:node_id])
    return unless filter_perms(@auth,node,'updater')
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
            elsif request.env["HTTP_REFERER"].include? "nodes"
              page.replace_html 'node_rack_node_assignments', :partial => 'nodes/node_rack_assignment', :locals => { :node => @node_rack_node_assignment.node }
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
    @node_rack_node_assignment = @object
    node_rack = @node_rack_node_assignment.node_rack
    return unless filter_perms(@auth,node_rack,'updater')
    node = @node_rack_node_assignment.node
    return unless filter_perms(@auth,node,'updater')

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
    @node_rack_node_assignment = @object
    @node_rack = @node_rack_node_assignment.node_rack
    return unless filter_perms(@auth,@node_rack,'updater')
    @node = @node_rack_node_assignment.node
    return unless filter_perms(@auth,@node,'updater')

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
          elsif request.env["HTTP_REFERER"].include? "nodes"
            page.replace_html 'node_rack_node_assignments', :partial => 'nodes/node_rack_assignment', :locals => { :node => @node }
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
