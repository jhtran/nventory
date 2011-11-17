class NodeSupportContractAssignmentsController < ApplicationController
  # sets the @auth object and @object
  before_filter :get_obj_auth
  before_filter :modelperms

  # POST /node_support_contract_assignments
  # POST /node_support_contract_assignments.xml
  def create
    support_contract = SupportContract.find(params[:node_support_contract_assignment][:support_contract_id])
    return unless filter_perms(@auth,support_contract,'updater')
    node = Node.find(params[:node_support_contract_assignment][:node_id])
    return unless filter_perms(@auth,node,'updater')
    @node_support_contract_assignment = NodeSupportContractAssignment.new(params[:node_support_contract_assignment])

    respond_to do |format|
      if @node_support_contract_assignment.save
        format.html {
          flash[:notice] = 'NodeSupportContractAssignment was successfully created.'
          redirect_to node_support_contract_assignment_url(@node_support_contract_assignment)
        }
        format.js {
          render(:update) { |page|
            # We expect this AJAX creation to come from one of two places,
            # the support_contract show page or the node show page. Depending on
            # which we do something slightly different.
            if request.env["HTTP_REFERER"].include? "support_contracts"
              page.replace_html 'nodes', :partial => 'support_contracts/node_assignments', :locals => { :support_contract => @node_support_contract_assignment.support_contract }
            elsif request.env["HTTP_REFERER"].include? "nodes"
              page.replace_html 'node_support_contract_assignments', :partial => 'nodes/support_contract_assignments', :locals => { :node => @node_support_contract_assignment.node }
            end
          }
        }
        format.xml  { head :created, :location => node_support_contract_assignment_url(@node_support_contract_assignment) }
      else
        format.html { render :action => "new" }
        format.js   { render(:update) { |page| page.alert(@node_support_contract_assignment.errors.full_messages) } }
        format.xml  { render :xml => @node_support_contract_assignment.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /node_support_contract_assignments/1
  # DELETE /node_support_contract_assignments/1.xml
  def destroy
    @node_support_contract_assignment = NodeSupportContractAssignment.find(params[:id])
    @support_contract = @node_support_contract_assignment.support_contract
    @node = @node_support_contract_assignment.node

    return unless filter_perms(@auth,@support_contract,['updater'])
    return unless filter_perms(@auth,@node,['updater'])

    begin
      @node_support_contract_assignment.destroy
    rescue Exception => destroy_error
      respond_to do |format|
        format.html {
          flash[:error] = destroy_error.message
          redirect_to node_support_contract_assignment_url(@node_support_contract_assignment) and return
        }
        format.js   { render(:update) { |page| page.alert(destroy_error.message) } }
        format.xml  { head :error } # FIXME?
      end
      return
    end

    # Success!
    respond_to do |format|
      format.html { redirect_to node_support_contract_assignments_url }
      format.js {
        if request.env["HTTP_REFERER"].include? "nodes"
          render(:update) { |page|
            page.replace_html 'node_support_contract_assignments', {:partial => 'nodes/support_contract_assignments', :locals => { :node => @node} }
          }
        elsif request.env["HTTP_REFERER"].include? "support_contracts"
          render(:update) { |page|
            page.replace_html 'nodes', {:partial => 'support_contracts/node_assignments',  :locals => { :support_contract => @node_support_contract_assignment.support_contract }}
          }
        end  
      }
      format.xml  { head :ok }
    end
  end 
end
