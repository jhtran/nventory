class VolumeNodeAssignmentsController < ApplicationController
  # GET /volume_node_assignments
  # GET /volume_node_assignments.xml
  def index
    sort = case params['sort']
           when "assigned_at" then "volume_node_assignments.assigned_at"
           when "assigned_at_reverse" then "volume_node_assignments.assigned_at DESC"
           end
    
    # if a sort was not defined we'll make one default
    if sort.nil?
      params['sort'] = VolumeNodeAssignment.default_search_attribute
      sort = 'volume_node_assignments.' + VolumeNodeAssignment.default_search_attribute
    end
    
    # XML doesn't get pagination
    if params[:format] && params[:format] == 'xml'
      @objects = VolumeNodeAssignment.find(:all, :order => sort)
    else
      @objects = VolumeNodeAssignment.paginate(:all,
                                             :order => sort,
                                             :page => params[:page])
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @objects.to_xml(:dasherize => false) }
    end
  end

  # GET /volume_node_assignments/1
  # GET /volume_node_assignments/1.xml
  def show
    @volume_node_assignment = VolumeNodeAssignment.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @volume_node_assignment.to_xml(:dasherize => false) }
    end
  end

  # GET /volume_node_assignments/new
  def new
    @volume_node_assignment = VolumeNodeAssignment.new
  end

  # GET /volume_node_assignments/1/edit
  def edit
    @volume_node_assignment = VolumeNodeAssignment.find(params[:id])
  end

  # POST /volume_node_assignments
  # POST /volume_node_assignments.xml
  def create
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
              page.hide 'create_node_assignment'
              page.show 'add_node_assignment_link'
            elsif request.env["HTTP_REFERER"].include? "nodes"
              page.replace_html 'volume_mounted', :partial => 'nodes/volume_mounted', :locals => { :node => @volume_node_assignment.node }
              page.hide 'create_volume_mounted'
              page.hide 'no_volumes'
              page.show 'add_volume_mounted_link'
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
    @volume_node_assignment = VolumeNodeAssignment.find(params[:id])

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
    @volume_node_assignment = VolumeNodeAssignment.find(params[:id])
    @volume = @volume_node_assignment.volume
    @node = @volume_node_assignment.node
    @volume_node_assignment.destroy

    respond_to do |format|
      format.html { redirect_to volume_node_assignments_url }
      format.js {
        render(:update) { |page|
          if request.env["HTTP_REFERER"].include? "volumes"
            page.replace_html 'volume_node_assignments', :partial => 'volumes/node_assignments', :locals => { :volume => @volume }
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
  
  # GET /volume_node_assignments/1/version_history
  def version_history
    @volume_node_assignment = VolumeNodeAssignment.find(params[:id])
    render :action => "version_table", :layout => false
  end
  
end
