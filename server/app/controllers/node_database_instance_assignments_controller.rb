class NodeDatabaseInstanceAssignmentsController < ApplicationController
  # sets the @auth object and @object
  before_filter :get_obj_auth
  before_filter :modelperms

  # GET /node_database_instance_assignments
  # GET /node_database_instance_assignments.xml
  def index
    ## BUILD MASTER HASH WITH ALL SUB-PARAMS ##
    allparams = {}
    allparams[:mainmodel] = NodeDatabaseInstanceAssignment
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

  # GET /node_database_instance_assignments/1
  # GET /node_database_instance_assignments/1.xml
  def show
    @node_database_instance_assignment = @object

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @node_database_instance_assignment.to_xml(:dasherize => false) }
    end
  end

  # GET /node_database_instance_assignments/new
  def new
    @node_database_instance_assignment = @object
  end

  # GET /node_database_instance_assignments/1/edit
  def edit
    @node_database_instance_assignment = @object
  end

  # POST /node_database_instance_assignments
  # POST /node_database_instance_assignments.xml
  def create
    @node_database_instance_assignment = NodeDatabaseInstanceAssignment.new(params[:node_database_instance_assignment])
    node = Node.find(params[:node_database_instance_assignment][:node_id])
    return unless filter_perms(@auth,node,['updater'])
    database_instance = DatabaseInstance.find(params[:node_database_instance_assignment][:database_instance_id])
    return unless filter_perms(@auth,database_instance,['updater'])

    respond_to do |format|
      if @node_database_instance_assignment.save
        format.html { 
          flash[:notice] = 'NodeDatabaseInstanceAssignment was successfully created.'
          redirect_to node_database_instance_assignment_url(@node_database_instance_assignment) 
        }
        format.js { 
          render(:update) { |page| 
            page.replace_html 'node_database_instance_assignments', :partial => 'nodes/database_instance_assignments', :locals => { :node => @node_database_instance_assignment.node }
            page.hide 'create_database_instance_assignment'
            page.show 'add_database_instance_assignment_link'
          }
        }
        format.xml  { head :created, :location => node_database_instance_assignment_url(@node_database_instance_assignment) }
      else
        format.html { render :action => "new" }
        format.js   { render(:update) { |page| page.alert(@node_database_instance_assignment.errors.full_messages) } }
        format.xml  { render :xml => @node_database_instance_assignment.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /node_database_instance_assignments/1
  # PUT /node_database_instance_assignments/1.xml
  def update
    @node_database_instance_assignment = @object
    node = @node_database_instance_assignment.node
    return unless filter_perms(@auth,node,['updater'])
    database_instace = @node_database_instance_assignment.database_instance
    return unless filter_perms(@auth,database_instance,['updater'])

    respond_to do |format|
      if @node_database_instance_assignment.update_attributes(params[:node_database_instance_assignment])
        flash[:notice] = 'NodeDatabaseInstanceAssignment was successfully updated.'
        format.html { redirect_to node_database_instance_assignment_url(@node_database_instance_assignment) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @node_database_instance_assignment.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /node_database_instance_assignments/1
  # DELETE /node_database_instance_assignments/1.xml
  def destroy
    @node_database_instance_assignment = @object
    @node = @node_database_instance_assignment.node
    return unless filter_perms(@auth,@node,['updater'])
    @node_database_instance_assignment.destroy
    return unless filter_perms(@auth,@database_instance,['updater'])

    respond_to do |format|
      format.html { redirect_to node_database_instance_assignments_url }
      format.js {
        render(:update) { |page|
          page.replace_html 'node_database_instance_assignments', {:partial => 'nodes/database_instance_assignments', :locals => { :node => @node} }
        }
      }
      format.xml  { head :ok }
    end
  end
  
  # GET /node_database_instance_assignments/1/version_history
  def version_history
    @node_database_instance_assignment = NodeDatabaseInstanceAssignment.find(params[:id])
    render :action => "version_table", :layout => false
  end
  
end
