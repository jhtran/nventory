class VolumeDriveAssignmentsController < ApplicationController
  # sets the @auth object and @object
  before_filter :get_obj_auth
  before_filter :modelperms

  # GET /volume_drive_assignments
  # GET /volume_drive_assignments.xml
  def index
    ## BUILD MASTER HASH WITH ALL SUB-PARAMS ##
    allparams = {}
    allparams[:mainmodel] = VolumeDriveAssignment
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

  # GET /volume_drive_assignments/1
  # GET /volume_drive_assignments/1.xml
  def show
    @volume_drive_assignment = @object

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @volume_drive_assignment.to_xml(:dasherize => false) }
    end
  end

  # GET /volume_drive_assignments/new
  def new
    @volume_drive_assignment = @object
  end

  # GET /volume_drive_assignments/1/edit
  def edit
    @volume_drive_assignment = @object
  end

  # POST /volume_drive_assignments
  # POST /volume_drive_assignments.xml
  def create
    @volume_drive_assignment = VolumeDriveAssignment.new(params[:volume_drive_assignment])
    volume = Volume.find(params[:volume_drive_assignment][:volume_id])
    return unless filter_perms(@auth,volume,['updater'])
    drive = Drive.find(params[:volume_drive_assignment][:drive_id])
    return unless filter_perms(@auth,drive,['updater'])

    respond_to do |format|
      if @volume_drive_assignment.save
        format.html {
          flash[:notice] = 'VolumeDriveAssignment was successfully created.'
          redirect_to volume_drive_assignment_url(@volume_drive_assignment)
        }
        format.js { 
          render(:update) { |page| 
            # We expect this AJAX creation to come from one of two places,
            # the rack show page or the node show page. Depending on
            # which we do something slightly different.
            if request.env["HTTP_REFERER"].include? "volumes"
              page.replace_html 'volume_drive_assignments', :partial => 'volumes/node_assignments', :locals => { :volume => @volume_drive_assignment.volume }
              page.hide 'create_node_assignment'
              page.show 'add_node_assignment_link'
            elsif request.env["HTTP_REFERER"].include? "nodes"
              page.replace_html 'volume_mounted', :partial => 'nodes/volume_mounted', :locals => { :node => @volume_drive_assignment.node }
              page.hide 'create_volume_mounted'
              page.hide 'no_volumes'
              page.show 'add_volume_mounted_link'
            end
          }
        }
        format.xml  { head :created, :location => volume_drive_assignment_url(@volume_drive_assignment) }
      else
        format.html { render :action => "new" }
        format.js   { render(:update) { |page| page.alert(@volume_drive_assignment.errors.full_messages) } }
        format.xml  { render :xml => @volume_drive_assignment.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /volume_drive_assignments/1
  # PUT /volume_drive_assignments/1.xml
  def update
    @volume_drive_assignment = @object
    volume = @volume_drive_assignment.volume
    return unless filter_perms(@auth,volume,['updater'])
    drive = @volume_drive_assignment.drive
    return unless filter_perms(@auth,drive,['updater'])

    respond_to do |format|
      if @volume_drive_assignment.update_attributes(params[:volume_drive_assignment])
        flash[:notice] = 'VolumeDriveAssignment was successfully updated.'
        format.html { redirect_to volume_drive_assignment_url(@volume_drive_assignment) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @volume_drive_assignment.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /volume_drive_assignments/1
  # DELETE /volume_drive_assignments/1.xml
  def destroy
    @volume_drive_assignment = @object
    @volume = @volume_drive_assignment.volume
    return unless filter_perms(@auth,@volume,['updater'])
    @drive = @volume_drive_assignment.drive
    return unless filter_perms(@auth,drive,['updater'])
    @node = @volume_drive_assignment.node
    @volume_drive_assignment.destroy

    respond_to do |format|
      format.html { redirect_to volume_drive_assignments_url }
      format.js {
        render(:update) { |page|
          if request.env["HTTP_REFERER"].include? "volumes"
            page.replace_html 'volume_drive_assignments', :partial => 'volumes/node_assignments', :locals => { :volume => @volume }
            page.hide 'create_volume_assignment'
            page.show 'add_volume_assignment_link'
          elsif request.env["HTTP_REFERER"].include? "nodes"
            page.replace_html 'volume_mounted', :partial => 'nodes/volume_mounted', :locals => { :node => @node }
            page.hide 'create_volume_mounted'
            page.show 'add_volume_mounted_link'
          end
        }
      }
      format.xml  { head :ok }
    end
  end
  
  # GET /volume_drive_assignments/1/version_history
  def version_history
    @volume_drive_assignment = VolumeDriveAssignment.find(params[:id])
    render :action => "version_table", :layout => false
  end
  
end
