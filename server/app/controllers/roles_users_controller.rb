class RolesUsersController < ApplicationController
  # sets the @auth object and @object
  before_filter :getauth
  before_filter :modelperms

  # GET /roles_users
  # GET /roles_users.xml
  def index
    special_joins = {}

    ## BUILD MASTER HASH WITH ALL SUB-PARAMS ##
    allparams = {}
    allparams[:mainmodel] = RolesUser
    allparams[:webparams] = params
    allparams[:special_joins] = special_joins

    results = Search.new(allparams).search
    flash[:error] = results[:errors].join('<br />') unless results[:errors].empty?
    includes = results[:includes]
    results[:requested_includes].each_pair{|k,v| includes[k] = v}
    @objects = results[:search_results]

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @objects.to_xml(:include => convert_includes(includes),
                                                   :dasherize => false) }
    end
  end

  # GET /roles_users/1
  # GET /roles_users/1.xml
  def show
    get_obj_auth(params[:refcontroller],params[:refid])
    @roles_user = RolesUser.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @roles_user.to_xml(:include => convert_includes(includes),
                                                  :dasherize => false) }
    end
  end

  # GET /roles_users/new
  def new
    get_obj_auth(params[:refcontroller],params[:refid])
    @roles_user = RolesUser.new
  end

  # GET /roles_users/1/edit
  def edit
    get_obj_auth(params[:refcontroller],params[:refid])
    @roles_user = RolesUser.find(params[:id])
  end

  # POST /roles_users
  # POST /roles_users.xml
  def create
    get_obj_auth(params[:refcontroller],params[:refid])
    @roles_user = RolesUser.new(params[:roles_user])

    respond_to do |format|
      if @roles_user.save
        flash[:notice] = 'RolesUser was successfully created.'
        format.html { redirect_to roles_user_url(@roles_user) }
        format.xml  { head :created, :location => roles_user_url(@roles_user) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @roles_user.errors.to_xml, :roles_user => :unprocessable_entity }
      end
    end
  end

  # PUT /roles_users/1
  # PUT /roles_users/1.xml
  def update
    get_obj_auth(params[:refcontroller],params[:refid])
    @roles_user = RolesUser.find(params[:id])

    respond_to do |format|
      if @roles_user.update_attributes(params[:roles_user])
        flash[:notice] = 'RolesUser was successfully updated.'
        format.html { redirect_to roles_user_url(@roles_user) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @roles_user.errors.to_xml, :roles_user => :unprocessable_entity }
      end
    end
  end

  # DELETE /roles_users/1
  # DELETE /roles_users/1.xml
  def destroy
    get_obj_auth(params[:refcontroller],params[:refid])
    @roles_user = RolesUser.find(params[:id])
    @roles_user.destroy
    flash[:error] = @roles_user.errors.on_base unless @roles_user.errors.empty?
    respond_to do |format|
      format.html { redirect_to roles_users_url }
      format.xml  { head :ok }
      format.js {
        # reget the @object model via get_obj_auth
        if params[:refcontroller] && params[:refid]
          # instance objects
          get_obj_auth(params[:refcontroller], params[:refid], :show)
          @objects = @object.allowed_roles if @object 
        else
          # classes
          get_obj_auth(params[:refcontroller], nil, :index)
          @objects = params[:refcontroller].classify.constantize.allowed_roles
        end
        render(:update) { |page|
            page.replace_html 'perms', :partial => 'shared/perms_table', :locals => { :perms => @objects, :refcontroller => params[:refcontroller], :refid => params[:refid] }
            unless (params[:refid].nil? || params[:refid].empty?) && controller.action_name != 'index'
              unless allow_admin(@object)
                page.hide 'perms'
                page.hide 'edit_delete'
              end
            else
              page.hide 'perms' unless allow_admin(params[:refcontroller].classify.constantize)
            end
        }
      }
    end
  end
  
  # GET /roles_users/1/version_history
  def version_history
    @roles_user = RolesUser.find(params[:id])
    render :action => "version_table", :layout => false
  end
  
  # GET /roles_users/field_names
  def field_names
    super(RolesUser)
  end

  # GET /roles_users/search
  def search
    @roles_user = RolesUser.find(:first)
    render :action => 'search'
  end
  
end
