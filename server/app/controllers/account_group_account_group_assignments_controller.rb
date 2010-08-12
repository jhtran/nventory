class AccountGroupAccountGroupAssignmentsController < ApplicationController
  # sets the @auth object and @object
  before_filter :get_obj_auth
  before_filter :modelperms

  # GET /account_group_account_group_assignments
  # GET /account_group_account_group_assignments.xml
  def index
    ## BUILD MASTER HASH WITH ALL SUB-PARAMS ##
    allparams = {}
    allparams[:mainmodel] = AccountGroupAccountGroupAssignment
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

  # GET /account_group_account_group_assignments/1
  # GET /account_group_account_group_assignments/1.xml
  def show
    @account_group_account_group_assignment = @object

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @account_group_account_group_assignment.to_xml(:dasherize => false) }
    end
  end

  # GET /account_group_account_group_assignments/new
  def new
    @account_group_account_group_assignment = @object
  end

  # GET /account_group_account_group_assignments/1/edit
  def edit
    @account_group_account_group_assignment = @object
  end

  # POST /account_group_account_group_assignments
  # POST /account_group_account_group_assignments.xml
  def create
    @account_group_account_group_assignment = AccountGroupAccountGroupAssignment.new(params[:account_group_account_group_assignment])
    parent = AccountGroup.find(params[:account_group_account_group_assignment][:parent_id])
    return unless filter_perms(@auth,parent,'updater')
    child = AccountGroup.find(params[:account_group_account_group_assignment][:child_id])
    return unless filter_perms(@auth,child,'updater')

    refcontroller = params[:refcontroller]
    refid = params[:refid]
    partial = params[:partial]
    div = params[:div]

    respond_to do |format|
      if @account_group_account_group_assignment.save
        
        format.html { 
          flash[:notice] = 'AccountGroupAccountGroupAssignment was successfully created.'
          redirect_to account_group_account_group_assignment_url(@account_group_account_group_assignment) 
        }
        format.js { 
          if ( (refcontroller == 'account_groups' && refid) && ( ref_obj = refcontroller.classify.constantize.find(refid) ) )
            render(:update) { |page|
              page.replace_html div, :partial => "#{refcontroller}/#{partial}", :locals => {:account_group => ref_obj}
              #page.replace_html 'child_group_assgns', :partial => 'account_groups/child_group_assignments', :locals => { :account_group => ref_obj }
            }
          end
        }
        format.xml  { head :created, :location => account_group_account_group_assignment_url(@account_group_account_group_assignment) }
      else
        format.html { render :action => "new" }
        format.js   { render(:update) { |page| page.alert(@account_group_account_group_assignment.errors.full_messages) } }
        format.xml  { render :xml => @account_group_account_group_assignment.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /account_group_account_group_assignments/1
  # PUT /account_group_account_group_assignments/1.xml
  def update
    @account_group_account_group_assignment = @object
    parent = @account_group_account_group_assignment.parent
    return unless filter_perms(@auth,parent,'updater')
    child = @account_group_account_group_assignment.child
    return unless filter_perms(@auth,child,'updater')

    respond_to do |format|
      if @account_group_account_group_assignment.update_attributes(params[:account_group_account_group_assignment])
        flash[:notice] = 'AccountGroupAccountGroupAssignment was successfully updated.'
        format.html { redirect_to account_group_account_group_assignment_url(@account_group_account_group_assignment) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @account_group_account_group_assignment.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /account_group_account_group_assignments/1
  # DELETE /account_group_account_group_assignments/1.xml
  def destroy
    @account_group_account_group_assignment = @object
    @parent_group = @account_group_account_group_assignment.parent_group
    return unless filter_perms(@auth,@parent,'updater')
    @child_group = @account_group_account_group_assignment.child_group
    return unless filter_perms(@auth,@child,'updater')
    
    begin
      @account_group_account_group_assignment.destroy
    rescue Exception => destroy_error
      respond_to do |format|
        format.html { 
          flash[:error] = destroy_error.message
          redirect_to account_group_account_group_assignment_url(@account_group_account_group_assignment) and return
        }
        format.js   { render(:update) { |page| page.alert(destroy_error.message) } }
        format.xml  { head :error } # FIXME?
      end
      return
    end

    refcontroller = params[:refcontroller]
    refid = params[:refid]
    partial = params[:partial]
    div = params[:div]

    respond_to do |format|
      format.html { redirect_to account_group_account_group_assignments_url }
      format.js {
        if ( (refcontroller == 'account_groups' && refid) && ( ref_obj = refcontroller.classify.constantize.find(refid) ) )
          render(:update) { |page|
            page.replace_html div, :partial => "#{refcontroller}/#{partial}", :locals => {:account_group => ref_obj}
            #page.replace_html 'child_group_assgns', :partial => 'account_groups/child_group_assignments', :locals => { :account_group => ref_obj }
          }
        end
      }
      format.xml  { head :ok }
    end
  end
  
  # GET /account_group_account_group_assignments/1/version_history
  def version_history
    @account_group_account_group_assignment = AccountGroupAccountGroupAssignment.find(params[:id])
    render :action => "version_table", :layout => false
  end
  
end
