class NodeGroupVipAssignmentsController < ApplicationController
  # sets the @auth object and @object
  before_filter :get_obj_auth
  before_filter :modelperms

  # GET /node_group_vip_assignments
  # GET /node_group_vip_assignments.xml
  def index
    ## BUILD MASTER HASH WITH ALL SUB-PARAMS ##
    allparams = {}
    allparams[:mainmodel] = NodeGroupVipAssignment
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

  # GET /node_group_vip_assignments/1
  # GET /node_group_vip_assignments/1.xml
  def show
    @node_group_vip_assignment = @object

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @node_group_vip_assignment.to_xml(:dasherize => false) }
    end
  end

  # GET /node_group_vip_assignments/new
  def new
    @node_group_vip_assignment = @object
  end

  # GET /node_group_vip_assignments/1/edit
  def edit
    @node_group_vip_assignment = @object
  end

  # POST /node_group_vip_assignments
  # POST /node_group_vip_assignments.xml
  def create
    @node_group_vip_assignment = NodeGroupVipAssignment.new(params[:node_group_vip_assignment])
    node_group = NodeGroup.find(params[:node_group_vip_assignment][:node_group_id])
    return unless filter_perms(@auth,node_group,'updater')
    vip = Vip.find(params[:node_group_vip_assignment][:vip_id])
    return unless filter_perms(@auth,vip,'updater')
    respond_to do |format|
      if @node_group_vip_assignment.save
        
        format.html { 
          flash[:notice] = 'NodeGroupVipAssignment was successfully created.'
          redirect_to node_group_vip_assignment_url(@node_group_vip_assignment) 
        }
        format.js { 
          render(:update) { |page| 
            request.env["HTTP_REFERER"] =~ /http:\/\/.*?\/(\w+)\/(\d+)/
            ref_class = $1
            if ref_class == 'node_groups'
              page.replace_html 'real_vips', :partial => 'node_groups/real_vip_assignments', :locals => { :node_group => @node_group_vip_assignment.node_group }
            elsif ref_class == 'vips'
              page.replace_html 'node_group_assignments', :partial => 'vips/node_group_assignments', :locals => { :vip => @node_group_vip_assignment.vip }
            end
          }
        }
        format.xml  { head :created, :location => node_group_vip_assignment_url(@node_group_vip_assignment) }
      else
        format.html { render :action => "new" }
        format.js   { render(:update) { |page| page.alert(@node_group_vip_assignment.errors.full_messages) } }
        format.xml  { render :xml => @node_group_vip_assignment.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /node_group_vip_assignments/1
  # PUT /node_group_vip_assignments/1.xml
  def update
    @node_group_vip_assignment = @object
    node_group = @node_group_vip_assignment.node_group
    return unless filter_perms(@auth,node_group,'updater')
    vip = @node_group_vip_assignmentvip.vip
    return unless filter_perms(@auth,vip,'updater')

    respond_to do |format|
      if @node_group_vip_assignment.update_attributes(params[:node_group_vip_assignment])
        flash[:notice] = 'NodeGroupVipAssignment was successfully updated.'
        format.html { redirect_to node_group_vip_assignment_url(@node_group_vip_assignment) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @node_group_vip_assignment.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /node_group_vip_assignments/1
  # DELETE /node_group_vip_assignments/1.xml
  def destroy
    @node_group_vip_assignment = @object
    @vip = @node_group_vip_assignment.vip
    return unless filter_perms(@auth,@vip,'updater')
    @node_group = @node_group_vip_assignment.node_group
    return unless filter_perms(@auth,@node_group,'updater')
    
    begin
      @node_group_vip_assignment.destroy
    rescue Exception => destroy_error
      respond_to do |format|
        format.html { 
          flash[:error] = destroy_error.message
          redirect_to node_group_vip_assignment_url(@node_group_vip_assignment) and return
        }
        format.js   { render(:update) { |page| page.alert(destroy_error.message) } }
        format.xml  { head :error } # FIXME?
      end
      return
    end
    
    # Success!
    respond_to do |format|
      format.html { redirect_to node_group_vip_assignments_url }
      format.js {
        render(:update) { |page|
          request.env["HTTP_REFERER"] =~ /http:\/\/.*?\/(\w+)\/(\d+)/
          ref_class = $1
          if ref_class == 'node_groups'
            page.replace_html 'real_vips', :partial => 'node_groups/real_vip_assignments', :locals => { :node_group => @node_group_vip_assignment.node_group }
            page.replace_html 'virtual_vips', :partial => 'node_groups/virtual_vip_assignments', :locals => { :node_group => @node_group_vip_assignment.node_group }
          elsif ref_class == 'vips'
            page.replace_html 'node_group_assignments', :partial => 'vips/node_group_assignments', :locals => { :vip => @node_group_vip_assignment.vip }
          end
        }
      }
      format.xml  { head :ok }
    end
  end
  
  # GET /node_group_vip_assignments/1/version_history
  def version_history
    @node_group_vip_assignment = NodeGroupVipAssignment.find(params[:id])
    render :action => "version_table", :layout => false
  end
  
end
