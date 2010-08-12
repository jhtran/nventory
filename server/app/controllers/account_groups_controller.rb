class AccountGroupsController < ApplicationController
  # sets the @auth object and @object
  before_filter :get_obj_auth
  before_filter :modelperms

  # GET /account_groups
  # GET /account_groups.xml
  def index
    special_joins = {}

    ## BUILD MASTER HASH WITH ALL SUB-PARAMS ##
    allparams = {}
    allparams[:mainmodel] = AccountGroup
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
						   :methods => [:virtual_accounts_names, :real_accounts_names],
                                                   :dasherize => false) }
    end
  end

  # GET /account_groups/1
  # GET /account_groups/1.xml
  def show
    @account_group = @object

    respond_to do |format|
      format.html {}
      format.xml  { render :xml => @account_group.to_xml(:include => convert_includes(includes), :dasherize => false) }
    end
  end

  # GET /account_groups/new
  def new
    @account_group = @object
  end

  # GET /account_groups/1/edit
  def edit
    @account_group = @object
  end

  # POST /account_groups
  # POST /account_groups.xml
  def create
    @account_group = AccountGroup.new(params[:account_group])
    
    account_save_successful = @account_group.save
    logger.debug "account_save_successful: #{account_save_successful}"
    
    if account_save_successful
      # Process any account group -> account group assignment creations
      account_group_assignment_save_successful = process_account_group_assignments()
      logger.debug "account_group_assignment_save_successful: #{account_group_assignment_save_successful}"
      # Process any account -> account group assignment creations
      account_assignment_save_successful = process_account_assignments()
      logger.debug "account_assignment_save_successful: #{account_assignment_save_successful}"
    end

    respond_to do |format|
      if account_save_successful && account_group_assignment_save_successful && account_assignment_save_successful
        flash[:notice] = 'Account group was successfully created.'
        format.html { redirect_to account_group_url(@account_group) }
        format.xml  { head :created, :location => account_group_url(@account_group) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @account_group.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /account_groups/1
  # PUT /account_groups/1.xml
  def update
    @account_group = @object
    if (defined?(params[:account_group_account_group_assignments][:child_groups]) && params[:account_group_account_group_assignments][:child_groups].include?('nil'))
      params[:account_group_account_group_assignments][:child_groups] = []
    end
    if (defined?(params[:account_group_account_assignments][:accounts]) && params[:account_group_account_assignments][:accounts].include?('nil'))
      params[:account_group_account_assignments][:accounts] = []
    end

    # Process any account group -> account group assignment updates
    account_group_assignment_save_successful = process_account_group_assignments()

    # Process any account -> account group assignment updates
    account_assignment_save_successful = process_account_assignments()

    respond_to do |format|
      if account_group_assignment_save_successful && account_assignment_save_successful && @account_group.update_attributes(params[:account_group])
        flash[:notice] = 'Account group was successfully updated.'
        format.html { redirect_to account_group_url(@account_group) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @account_group.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /account_groups/1
  # DELETE /account_groups/1.xml
  def destroy
    @account_group = @object
    @account_group.destroy

    respond_to do |format|
      format.html { redirect_to account_groups_url }
      format.xml  { head :ok }
    end
  end
  
  # GET /account_groups/1/version_history
  def version_history
    @account_group = AccountGroup.find(params[:id])
    render :action => "version_table", :layout => false
  end
  
  # GET /account_groups/field_names
  def field_names
    super(AccountGroup)
  end

  # GET /account_groups/search
  def search
    @account_group = AccountGroup.find(:first)
    render :action => 'search'
  end
  
  def process_account_group_assignments
    r = true
    if params.include?(:account_group_account_group_assignments)
      if params[:account_group_account_group_assignments].include?(:child_groups)
        groupids = params[:account_group_account_group_assignments][:child_groups].collect { |g| g.to_i }
        r = @account_group.set_child_groups(groupids)
      end
    end
    r
  end
  private :process_account_group_assignments

  def process_account_assignments
    r = true
    if params.include?(:account_group_account_assignments)
      if params[:account_group_account_assignments].include?(:accounts)
        accountids = params[:account_group_account_assignments][:accounts].collect { |n| n.to_i }
        r = @account_group.set_accounts(accountids)
      end
    end
    r
  end
  private :process_account_assignments

  def get_deps
    if params[:id] && params[:partial]
      @account_group = AccountGroup.find(params[:id])
      render :partial => params[:partial], :locals => { :account_group => @account_group, :virtuals_through => @virtuals_through } 
    else
      render :text => ''
    end
  end

  def graph_account_groups
    @account_group = AccountGroup.find(params[:id])
    @graphobjs = {}
    @graph = GraphViz::new( "G", "output" => "png" )
    @dots = {}
    @graphobjs[@account_group.name.downcase.gsub(/-/,'')] = @graph.add_node(@account_group.name.downcase.gsub(/-/,''), :label => "#{@account_group.name.downcase}", :shape => 'rectangle', :color => "yellow", :style => "filled")
    # walk the account_group's parents account_group tree
    dot_parent_groups(@account_group)
    # walk the account_group's children account_group tree 
    dot_child_groups(@account_group)

    ## Write the function to add all the dot points from the hash
    @dots.each_pair do |parent,children|
      children.uniq.each do |child|
        @graph.add_edge( @graphobjs[parent],@graphobjs[child] )
      end
    end
    @graph.output( :output => 'gif',:file => "public/images/#{@account_group.name}_account_grouptree.gif" )
    respond_to do |format|
      format.html # graph_account_groups.html.erb
    end
  end

  def dot_child_groups(ng)
    ng.child_groups.each do |child_account_group|
      @graphobjs[child_account_group.name.gsub(/[-.]/,'')] = @graph.add_node(child_account_group.name.gsub(/[-.]/,''), :label => "#{child_account_group.name}", :shape => 'rectangle')
      @dots[ng.name.gsub(/[-.]/,'')] = [] unless @dots[ng.name.gsub(/[-.]/,'')]
      @dots[ng.name.gsub(/[-.]/,'')] << child_account_group.name.gsub(/[-.]/,'')
      unless child_account_group.child_groups.empty?
        dot_child_groups(child_account_group)
      end
    end
  end
  private :dot_child_groups

  def dot_parent_groups(ng)
    ng.parent_groups.each do |parent_account_group|
      @graphobjs[parent_account_group.name.gsub(/[-.]/,'')] = @graph.add_node(parent_account_group.name.gsub(/[-.]/,''), :label => "#{parent_account_group.name}", :shape => 'rectangle')
      @dots[parent_account_group.name.gsub(/[-.]/,'')] = [] unless @dots[parent_account_group.name.gsub(/[-.]/,'')]
      @dots[parent_account_group.name.gsub(/[-.]/,'')] << ng.name.gsub(/[-.]/,'')
      unless parent_account_group.parent_groups.empty?
        dot_parent_groups(parent_account_group)
      end
    end
  end
  private :dot_parent_groups

  # deletes a obj from a user's list of granted permissions (opposite of delauth)
  def removeauth
    @object= AccountGroup.find(params[:id])
    if filter_perms(@auth,@object,'admin')
      roles_user = RolesUser.find(params[:refid])
      role = roles_user.role
      if role.authorizable
        @object.has_no_role role.name, role.authorizable
      elsif role.authorizable_type && !role.authorizable_id
        @object.has_no_role role.name, role.authorizable_type.constantize
      elsif !role.authorizable_type && !role.authorizable_id
        @object.has_no_role role.name
      end
  
      respond_to do |format|
        format.js {
          render(:update) { |page|
            page.replace_html 'roles', :partial => 'shared/roles', :locals => { :obj => @object}
          }
        }
      end
    end
  end

  # add a GLOBAL APP-WIDE role to account_group 
  def addglobalrole
    @object= AccountGroup.find(params[:id])
    if filter_perms(@auth,nil,'admin')
      role_name = params[:rolename]
      @object.has_role role_name
      respond_to do |format|
        format.js {
          render(:update) { |page|
            page.replace_html 'roles', :partial => 'shared/roles', :locals => { :obj => @object}
          }
        }
      end
    end
  end

end
