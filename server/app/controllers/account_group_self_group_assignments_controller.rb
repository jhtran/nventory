class AccountGroupSelfGroupAssignmentsController < ApplicationController
  # sets the @auth object and @object
  before_filter :get_obj_auth
  before_filter :modelperms

  # GET /account_group_self_group_assignments
  # GET /account_group_self_group_assignments.xml
  def index
    ## BUILD MASTER HASH WITH ALL SUB-PARAMS ##
    allparams = {}
    allparams[:mainmodel] = AccountGroupSelfGroupAssignment
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

  # GET /account_group_self_group_assignments/1
  # GET /account_group_self_group_assignments/1.xml
  def show
    @account_group_self_group_assignment = @object

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @account_group_self_group_assignment.to_xml(:dasherize => false) }
    end
  end

  # GET /account_group_self_group_assignments/new
  def new
    @account_group_self_group_assignment = @object
  end

  # GET /account_group_self_group_assignments/1/edit
  def edit
    @account_group_self_group_assignment = @object
  end

  # POST /account_group_self_group_assignments
  # POST /account_group_self_group_assignments.xml
  def create
    account_group = AccountGroup.find(params[:account_group_self_group_assignment][:account_group_id])
    return unless filter_perms(@auth,account_group,'updater')
    self_group = AccountGroup.find(params[:account_group_self_group_assignment][:self_group_id])
    return unless filter_perms(@auth,self_group,'updater')
    @account_group_self_group_assignment = AccountGroupSelfGroupAssignment.new(params[:account_group_self_group_assignment])

    if request.env["HTTP_REFERER"] =~ /http:\/\/.*?\/(\w+)\/(\d+)/
      ref_class = $1.singularize
      ref_id = $2.to_i
    end

    respond_to do |format|
      if @account_group_self_group_assignment.save
        
        format.html { 
          flash[:notice] = 'AccountGroupSelfGroupAssignment was successfully created.'
          redirect_to account_group_self_group_assignment_url(@account_group_self_group_assignment) 
        }
        format.js { 
          render(:update) { |page| 
            if ref_class == 'account_group'
              page.replace_html 'real_accounts', :partial => 'account_groups/real_account_assignments', :locals => { :account_group => @account_group_self_group_assignment.account_group }
              page.replace_html 'virtual_accounts', :partial => 'account_groups/virtual_account_assignments', :locals => { :account_group => @account_group_self_group_assignment.account_group }
            elsif ref_class == 'account'
              page.replace_html 'account_groups', :partial => 'accounts/account_group_assignments', :locals => { :account => @account_group_self_group_assignment.self_group.authz}
            end
          } 
        }
        format.xml  { head :created, :location => account_group_self_group_assignment_url(@account_group_self_group_assignment) }
      else
        format.html { render :action => "new" }
        format.js   { render(:update) { |page| page.alert(@account_group_self_group_assignment.errors.full_messages) } }
        format.xml  { render :xml => @account_group_self_group_assignment.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /account_group_self_group_assignments/1
  # PUT /account_group_self_group_assignments/1.xml
  def update
    @account_group_self_group_assignment = @object

    respond_to do |format|
      if @account_group_self_group_assignment.update_attributes(params[:account_group_self_group_assignment])
        flash[:notice] = 'AccountGroupSelfGroupAssignment was successfully updated.'
        format.html { redirect_to account_group_self_group_assignment_url(@account_group_self_group_assignment) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @account_group_self_group_assignment.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /account_group_self_group_assignments/1
  # DELETE /account_group_self_group_assignments/1.xml
  def destroy
    @account_group_self_group_assignment = @object
    @self_group = @account_group_self_group_assignment.self_group
    return unless filter_perms(@auth,@self_group,'updater')
    @account_group = @account_group_self_group_assignment.account_group
    return unless filter_perms(@auth,@account_group,'updater')

    if request.env["HTTP_REFERER"] =~ /http:\/\/.*?\/(\w+)\/(\d+)/
      ref_class = $1.singularize
      ref_id = $2.to_i
    end
    
    begin
      @account_group_self_group_assignment.destroy
    rescue Exception => destroy_error
      respond_to do |format|
        format.html { 
          flash[:error] = destroy_error.message
          redirect_to account_group_self_group_assignment_url(@account_group_self_group_assignment) and return
        }
        format.js   { render(:update) { |page| page.alert(destroy_error.message) } }
        format.xml  { head :error } # FIXME?
      end
      return
    end
    
    # Success!
    respond_to do |format|
      format.html { redirect_to account_group_self_group_assignments_url }
      format.js { 
        render(:update) { |page| 
          if ref_class == 'account_group'
            page.replace_html 'real_accounts', :partial => 'account_groups/real_account_assignments', :locals => { :account_group => @account_group_self_group_assignment.account_group }
            page.replace_html 'virtual_accounts', :partial => 'account_groups/virtual_account_assignments', :locals => { :account_group => @account_group_self_group_assignment.account_group }
          elsif ref_class == 'account'
            page.replace_html 'account_groups', :partial => 'accounts/account_group_assignments', :locals => { :account=> @account_group_self_group_assignment.self_group.authz}
          end
        } 
      }
      format.xml  { head :ok }
    end
  end
  
  # GET /account_group_self_group_assignments/1/version_history
  def version_history
    @account_group_self_group_assignment = AccountGroupSelfGroupAssignment.find(params[:id])
    render :action => "version_table", :layout => false
  end
  
end
