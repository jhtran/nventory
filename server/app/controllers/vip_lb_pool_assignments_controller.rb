class VipLbPoolAssignmentsController < ApplicationController
  # GET /vip_lb_pool_assignments
  # GET /vip_lb_pool_assignments.xml
  def index
    sort = case params['sort']
           when "assigned_at" then "vip_lb_pool_assignments.assigned_at"
           when "assigned_at_reverse" then "vip_lb_pool_assignments.assigned_at DESC"
           end
    
    # if a sort was not defined we'll make one default
    if sort.nil?
      params['sort'] = VipLbPoolAssignment.default_search_attribute
      sort = 'vip_lb_pool_assignments.' + VipLbPoolAssignment.default_search_attribute
    end
    
    # XML doesn't get pagination
    if params[:format] && params[:format] == 'xml'
      @objects = VipLbPoolAssignment.find(:all, :order => sort)
    else
      @objects = VipLbPoolAssignment.paginate(:all,
                                             :order => sort,
                                             :page => params[:page])
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @objects.to_xml(:dasherize => false) }
    end
  end

  # GET /vip_lb_pool_assignments/1
  # GET /vip_lb_pool_assignments/1.xml
  def show
    @vip_lb_pool_assignment = VipLbPoolAssignment.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @vip_lb_pool_assignment.to_xml(:dasherize => false) }
    end
  end

  # GET /vip_lb_pool_assignments/new
  def new
    @vip_lb_pool_assignment = VipLbPoolAssignment.new
  end

  # GET /vip_lb_pool_assignments/1/edit
  def edit
    @vip_lb_pool_assignment = VipLbPoolAssignment.find(params[:id])
  end

  # POST /vip_lb_pool_assignments
  # POST /vip_lb_pool_assignments.xml
  def create
    @vip_lb_pool_assignment = VipLbPoolAssignment.new(params[:vip_lb_pool_assignment])

    respond_to do |format|
      if @vip_lb_pool_assignment.save
        format.html {
          flash[:notice] = 'VipLbPoolAssignment was successfully created.'
          redirect_to vip_lb_pool_assignment_url(@vip_lb_pool_assignment)
        }
        format.js { 
          render(:update) { |page| 
            # We expect this AJAX creation to come from one of two places,
            # the vip show page or the lb_pool show page. Depending on
            # which we do something slightly different.
            if request.env["HTTP_REFERER"].include? "vips"
              page.replace_html 'vip_lb_pool_assignments', :partial => 'vips/lb_pool_assignments', :locals => { :vip => @vip_lb_pool_assignment.vip }
              page.replace_html 'node_assignments', :partial => 'vips/node_assignments', :locals => { :vip => @vip_lb_pool_assignment.vip }
              page.hide 'create_lb_pool_assignment'
              page.show 'add_lb_pool_assignment_link'
            elsif request.env["HTTP_REFERER"].include? "lb_pools"
              page.replace_html 'vip_lb_pool_assignments', :partial => 'lb_pools/vip_assignment', :locals => { :lb_pool => @vip_lb_pool_assignment.lb_pool }
              page.hide 'create_vip_assignment'
              page.show 'add_vip_assignment_link'
            end
          }
        }
        format.xml  { head :created, :location => vip_lb_pool_assignment_url(@vip_lb_pool_assignment) }
      else
        format.html { render :action => "new" }
        format.js   { render(:update) { |page| page.alert(@vip_lb_pool_assignment.errors.full_messages) } }
        format.xml  { render :xml => @vip_lb_pool_assignment.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /vip_lb_pool_assignments/1
  # PUT /vip_lb_pool_assignments/1.xml
  def update
    @vip_lb_pool_assignment = VipLbPoolAssignment.find(params[:id])

    respond_to do |format|
      if @vip_lb_pool_assignment.update_attributes(params[:vip_lb_pool_assignment])
        flash[:notice] = 'VipLbPoolAssignment was successfully updated.'
        format.html { redirect_to vip_lb_pool_assignment_url(@vip_lb_pool_assignment) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @vip_lb_pool_assignment.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /vip_lb_pool_assignments/1
  # DELETE /vip_lb_pool_assignments/1.xml
  def destroy
    @vip_lb_pool_assignment = VipLbPoolAssignment.find(params[:id])
    @vip = @vip_lb_pool_assignment.vip
    @lb_pool = @vip_lb_pool_assignment.lb_pool
    @vip_lb_pool_assignment.destroy

    respond_to do |format|
      format.html { redirect_to vip_lb_pool_assignments_url }
      format.js {
        render(:update) { |page|
          page.replace_html 'vip_lb_pool_assignments', {:partial => 'vips/lb_pool_assignments', :locals => { :vip => @vip} }
          # We expect this AJAX deletion to come from one of two places,
          # the vip show page or the lb_pool show page. Depending on
          # which we do something slightly different.
          if request.env["HTTP_REFERER"].include? "vips"
            page.replace_html 'vip_lb_pool_assignments', :partial => 'vips/lb_pool_assignments', :locals => { :vip => @vip }
            page.replace_html 'node_assignments', :partial => 'vips/node_assignments', :locals => { :vip => @vip }
            page.hide 'create_lb_pool_assignment'
            page.show 'add_lb_pool_assignment_link'
          elsif request.env["HTTP_REFERER"].include? "lb_pools"
            page.replace_html 'vip_lb_pool_assignments', :partial => 'lb_pools/vip_assignment', :locals => { :lb_pool => @lb_pool }
            page.hide 'create_vip_assignment'
            page.show 'add_vip_assignment_link'
          end
        }
      }
      format.xml  { head :ok }
    end
  end
  
  # GET /vip_lb_pool_assignments/1/version_history
  def version_history
    @vip_lb_pool_assignment = VipLbPoolAssignment.find(params[:id])
    render :action => "version_table", :layout => false
  end
  
end
