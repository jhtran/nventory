class NodeGroupNodeAssignmentsController < ApplicationController
  # sets the @auth object and @object
  before_filter :get_obj_auth
  before_filter :modelperms

  # GET /node_group_node_assignments
  # GET /node_group_node_assignments.xml
  def index
    ## BUILD MASTER HASH WITH ALL SUB-PARAMS ##
    allparams = {}
    allparams[:mainmodel] = NodeGroupNodeAssignment
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

  # GET /node_group_node_assignments/1
  # GET /node_group_node_assignments/1.xml
  def show
    @node_group_node_assignment = @object

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @node_group_node_assignment.to_xml(:dasherize => false) }
    end
  end

  # GET /node_group_node_assignments/new
  def new
    @node_group_node_assignment = @object
  end

  # GET /node_group_node_assignments/1/edit
  def edit
    @node_group_node_assignment = @object
  end

  # POST /node_group_node_assignments
  # POST /node_group_node_assignments.xml
  def create
    # unfortunately, this is overlapping with model validation but can't think of better way to do it
      # ensures both objs are authorized prior to allow user to create the ngna
    node_group = NodeGroup.find(params[:node_group_node_assignment][:node_group_id])
    return unless filter_perms(@auth,node_group,['updater']) 
    node = Node.find(params[:node_group_node_assignment][:node_id])
    return unless filter_perms(@auth,node,['updater'])

    @node_group_node_assignment = NodeGroupNodeAssignment.new(params[:node_group_node_assignment])

    respond_to do |format|
      if @node_group_node_assignment.save
        flash[:notice] = 'NodeGroupNodeAssignment was successfully created.'
        format.html { 
          redirect_to node_group_node_assignment_url(@node_group_node_assignment) 
        }
        format.js { 
          if request.env["HTTP_REFERER"].include? "nodes"
            render(:update) { |page| 
              page.replace_html 'node_group_node_assignments', :partial => 'nodes/node_group_assignments', :locals => { :node => @node_group_node_assignment.node }
            }
          elsif request.env["HTTP_REFERER"].include? "node_groups"
            render(:update) { |page| 
              page.replace_html 'real_nodes', :partial => 'node_groups/real_node_assignments', :locals => { :node_group => @node_group_node_assignment.node_group }
            }
          elsif params[:div] && (params[:refcontroller] == 'reports')
            link = "<a href='/node_groups/#{@node_group_node_assignment.node_group.id}'>#{@node_group_node_assignment.node_group.name}</a>"
            render(:update) { |page| 
              page.replace_html params[:div], :text=> link
              page.hide "#{params[:div]}_form"
            }
          end
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
    @node_group_node_assignment = @object
    @node = @node_group_node_assignment.node
    @node_group = @node_group_node_assignment.node_group
    return unless filter_perms(@auth,@node_group,['updater'])
    return unless filter_perms(@auth,@node,['updater'])

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
    @node_group_node_assignment = @object
    @node = @node_group_node_assignment.node
    @node_group = @node_group_node_assignment.node_group
    return unless filter_perms(@auth,@node_group,['updater'])
    return unless filter_perms(@auth,@node,['updater'])
    
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
        if request.env["HTTP_REFERER"].include? "nodes"
          render(:update) { |page| 
            page.replace_html 'node_group_node_assignments', {:partial => 'nodes/node_group_assignments', :locals => { :node => @node} }
          }
        elsif request.env["HTTP_REFERER"].include? "node_groups"
          render(:update) { |page| 
            page.replace_html 'real_nodes', :partial => 'node_groups/real_node_assignments', :locals => { :node_group => @node_group_node_assignment.node_group }
            page.replace_html 'virtual_nodes', :partial => 'node_groups/virtual_node_assignments', :locals => { :node_group => @node_group_node_assignment.node_group }
          }
        end
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
