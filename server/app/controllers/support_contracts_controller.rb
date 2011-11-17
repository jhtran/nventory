class SupportContractsController < ApplicationController
  # sets the @auth object and @object
  before_filter :get_obj_auth
  before_filter :modelperms

  # GET /support_contracts
  # GET /support_contracts.xml
  def index
    special_joins = {}

    ## BUILD MASTER HASH WITH ALL SUB-PARAMS ##
    allparams = {}
    allparams[:mainmodel] = SupportContract
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

  # GET /support_contracts/1
  # GET /support_contracts/1.xml
  def show
    @support_contract = @object

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @support_contract.to_xml(:include => convert_includes(includes),
                                                :dasherize => false) }
    end
  end

  # GET /support_contracts/new
  def new
    @support_contract = @object
    respond_to do |format|
      format.html # show.html.erb 
      format.js  { render :action => "inline_new", :layout => false }
    end
  end
  
  # GET /support_contracts/1/edit
  def edit
    @support_contract = @object
  end

  # POST /support_contracts
  # POST /support_contracts.xml
  def create
    @support_contract = SupportContract.new(params[:support_contract])
    respond_to do |format|
      if @support_contract.save
        flash[:notice] = 'SupportContract was successfully created.'
        format.html { redirect_to support_contract_url(@support_contract) }
        format.xml  { head :created, :location => support_contract_url(@support_contract) }
      else
        format.html { render :action => "new" }
        format.js   { render(:update) { |page| page.alert(@support_contract.errors.full_messages) } }
        format.xml  { render :xml => @support_contract.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /support_contracts/1
  # PUT /support_contracts/1.xml
  def update
    @support_contract = @object

    respond_to do |format|
      if @support_contract.update_attributes(params[:support_contract])
        flash[:notice] = 'SupportContract was successfully updated.'
        format.html { redirect_to support_contract_url(@support_contract) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @support_contract.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /support_contracts/1
  # DELETE /support_contracts/1.xml
  def destroy
    @support_contract = @object
    begin
      @support_contract.destroy
    rescue Exception => destroy_error
      respond_to do |format|
        flash[:error] = destroy_error.message
        format.html { redirect_to support_contract_url(@support_contract) and return}
        format.xml  { head :error } # FIXME?
      end
    end

    # Success!
    respond_to do |format|
      format.html { redirect_to support_contracts_url }
      format.xml  { head :ok }
    end
  end

  # GET /support_contracts/1/version_history
  def version_history
    @support_contract = SupportContract.find(params[:id]) 
    render :action => "version_table", :layout => false
  end

  def get_deps
    if params[:id] && params[:partial]
      @support_contract = SupportContract.find(params[:id])
      render :partial => params[:partial], :locals => { :support_contract => @support_contract }
    else
      render :text => ''
    end
  end

  # GET /support_contracts/field_names
  def field_names
    super(SupportContract)
  end
end
