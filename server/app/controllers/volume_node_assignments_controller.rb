class VolumeNodeAssignmentsController < ApplicationController
  # sets the @auth object and @object
  before_filter :get_obj_auth
  before_filter :modelperms

  # GET /volume_node_assignments
  # GET /volume_node_assignments.xml
  def index
    ## BUILD MASTER HASH WITH ALL SUB-PARAMS ##
    allparams = {}
    allparams[:mainmodel] = VolumeNodeAssignment
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

  # GET /volume_node_assignments/1
  # GET /volume_node_assignments/1.xml
  def show
    @volume_node_assignment = @object

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @volume_node_assignment.to_xml(:dasherize => false) }
    end
  end

  # GET /volume_node_assignments/new
  def new
    @volume_node_assignment = @object
  end

  # GET /volume_node_assignments/1/edit
  def edit
    @volume_node_assignment = @object
  end

  # POST /volume_node_assignments
  # POST /volume_node_assignments.xml
  def create
    volume = Volume.find(params[:volume_node_assignment][:volume_id])
    return unless filter_perms(@auth,volume,['updater'])
    node = Node.find(params[:volume_node_assignment][:node_id])
    return unless filter_perms(@auth,node,['updater'])
    @volume_node_assignment = VolumeNodeAssignment.new(params[:volume_node_assignment])

    respond_to do |format|
      if @volume_node_assignment.save
        format.html {
          flash[:notice] = 'VolumeNodeAssignment was successfully created.'
          redirect_to volume_node_assignment_url(@volume_node_assignment)
        }
        format.js { 
          render(:update) { |page| 
            # We expect this AJAX creation to come from one of two places,
            # the rack show page or the node show page. Depending on
            # which we do something slightly different.
            if request.env["HTTP_REFERER"].include? "volumes"
              page.replace_html 'volume_node_assignments', :partial => 'volumes/node_assignments', :locals => { :volume => @volume_node_assignment.volume }
            elsif request.env["HTTP_REFERER"].include? "nodes"
              page.replace_html 'volume_mounted', :partial => 'nodes/volume_mounted', :locals => { :node => @volume_node_assignment.node }
            end
          }
        }
        format.xml  { head :created, :location => volume_node_assignment_url(@volume_node_assignment) }
      else
        format.html { render :action => "new" }
        format.js   { render(:update) { |page| page.alert(@volume_node_assignment.errors.full_messages) } }
        format.xml  { render :xml => @volume_node_assignment.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /volume_node_assignments/1
  # PUT /volume_node_assignments/1.xml
  def update
    @volume_node_assignment = @object
    @volume = @volume_node_assignment.volume
    @node = @volume_node_assignment.node
    return unless filter_perms(@auth,@volume,['updater'])
    return unless filter_perms(@auth,@node,['updater'])

    respond_to do |format|
      if @volume_node_assignment.update_attributes(params[:volume_node_assignment])
        flash[:notice] = 'VolumeNodeAssignment was successfully updated.'
        format.html { redirect_to volume_node_assignment_url(@volume_node_assignment) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @volume_node_assignment.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /volume_node_assignments/1
  # DELETE /volume_node_assignments/1.xml
  def destroy
    @volume_node_assignment = @object
    @volume = @volume_node_assignment.volume
    @node = @volume_node_assignment.node
    return unless filter_perms(@auth,@volume,['updater'])
    return unless filter_perms(@auth,@node,['updater'])
    @volume_node_assignment.destroy
    respond_to do |format|
      format.html { redirect_to volume_node_assignments_url }
      format.js {
        render(:update) { |page|
          if request.env["HTTP_REFERER"].include? "volumes"
            page.replace_html 'volume_node_assignments', :partial => 'volumes/node_assignments', :locals => { :volume => @volume }
          elsif request.env["HTTP_REFERER"].include? "nodes"
            page.replace_html 'volume_mounted', :partial => 'nodes/volume_mounted', :locals => { :node => @node }
          end
        }
      }
      format.xml  { head :ok }
    end
  end
  
  # GET /volume_node_assignments/1/version_history
  def version_history
    @volume_node_assignment = VolumeNodeAssignment.find(params[:id])
    render :action => "version_table", :layout => false
  end
  
end
