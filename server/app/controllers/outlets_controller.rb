class OutletsController < ApplicationController
  # sets the @auth object and @object
  before_filter :get_obj_auth
  before_filter :modelperms

  # GET /outlets
  # GET /outlets.xml

  def index
    ## BUILD MASTER HASH WITH ALL SUB-PARAMS ##
    allparams = {}
    allparams[:mainmodel] = Outlet
    allparams[:webparams] = params
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

  # GET /outlets/1
  # GET /outlets/1.xml
  def show
    @outlet = @object

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @outlet.to_xml(:include => convert_includes(includes),
                                                  :dasherize => false) }
    end
  end

  # GET /outlets/new
  def new
    @outlet = @object
    @consumers = Node.find(:all, :order => 'name').collect { |n| [ n.name, n.id ] }
  end

  # GET /outlets/1/edit
  def edit
    @outlet = @object
    if params[:consumer_type] == "NetworkInterface"
      results = params[:consumer_type].constantize.find(:all, :joins => {:node => {}}, :conditions => ["nodes.name is not ? and interface_type = ? and network_interfaces.name not like ?",nil,"Ethernet",'lo%'],:order => 'nodes.name' )
      @consumer_type = params[:consumer_type]
      @consumers = results.collect { |consumer| [ "#{consumer.node.name}:#{consumer.name}", consumer.id ] }
    else
      @consumers = Node.find(:all, :order => 'name').collect { |n| [ n.name, n.id ] }
    end
    respond_to do |format|
      format.html # show.html.erb
      format.js  { render :action => 'inline_consumer_edit', :layout => false }
    end
  end

  # POST /outlets
  # POST /outlets.xml
  def create
    @outlet = Outlet.new(params[:outlet])
    producer = @outlet.producer

    respond_to do |format|
      if @outlet.save
        flash[:notice] = 'Outlet was successfully created.'
        format.js {
          render(:update) { |page|
            # We expect this AJAX creation to come from outlets
            if request.env["HTTP_REFERER"].include? "nodes"
              page.replace_html 'outlets', {:partial => 'nodes/outlets', :locals => { :node => producer } }
              page.hide 'create_outlet'
              if producer.hardware_profile.outlet_count
                page.show 'add_outlet_link' if producer.hardware_profile.outlet_count == 0 
                page.show 'add_outlet_link' unless producer.hardware_profile.outlet_count <= producer.produced_outlets.size
              end
            end
          }
        }
        format.html { redirect_to outlet_url(@outlet) }
        format.xml  { head :created, :location => outlet_url(@outlet) }
      else
        format.html { render :action => "new" }
        format.js   { 
          render(:update) { |page| 
            page.hide 'create_outlet'
            page.show 'add_outlet_link'
            page.alert(@outlet.errors.full_messages) 
          }
        }
        format.xml  { render :xml => @outlet.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /outlets/1
  # PUT /outlets/1.xml
  def update
    @outlet = @object

    respond_to do |format|
      if @outlet.update_attributes(params[:outlet])
        flash[:notice] = 'Outlet was successfully updated.'
        format.html { redirect_to outlet_url(@outlet) }
        format.js { 
          render(:update) { |page| 
            page.replace_html dom_id(@outlet), :partial => 'consumer', :locals => { :outlet => @outlet }
          }
        }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.js   { render(:update) { |page| page.alert(@outlet.errors.full_messages) } }
        format.xml  { render :xml => @outlet.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /outlets/1
  # DELETE /outlets/1.xml
  def destroy
    @outlet = @object
    producer = @outlet.producer
    @outlet.destroy

    respond_to do |format|
      format.html { redirect_to outlets_url }
      format.js {
        render(:update) { |page|
          page.replace_html 'outlets', {:partial => 'nodes/outlets', :locals => { :node => producer} }
          page.show 'add_outlet_link'
        }
      }
      format.xml  { head :ok }
    end
  end
  
  # GET /outlets/1/version_history
  def version_history
    @outlet = Outlet.find(params[:id])
    render :action => "version_table", :layout => false
  end
  
  # GET /outlets/1/version_history
  def consumer
    @outlet = Outlet.find(params[:id])
    render :action => '_consumer', :layout => false
  end
  
  # GET /outlets/field_names
  def field_names
    super(Outlet)
  end

  # GET /outlets/search
  def search
    @outlet = Outlet.find(:first)
    render :action => 'search'
  end

  def get_producer_consumer
    outlet_type = request.raw_post
    # param for :producer_id
    @producers = Node.find( :all, :joins => {:hardware_profile => {}}, :order => 'nodes.name',
                            :conditions => ["hardware_profiles.outlet_type = ?", outlet_type]).collect { |node| [node.name, node.id] }
    # param for :consumer_id
    if outlet_type == 'Network'
      @consumers = NetworkInterface.find( :all, :conditions => "network_interfaces.name not like 'lo%'", :order => 'nodes.name',
                                          :joins => {:node => {}}).collect { |nic| [ "#{nic.node.name} [ #{nic.name} ]", nic.id ] }
    else
      @consumers = Node.find(:all, :select => "id,name", :order => 'name').collect { |node| [ node.name, node.id ] }
    end
    # param for :consumer_type
    outlet_type == "Network" ? @consumer_type = 'NetworkInterface' : @consumer_type = 'Node'

    render :partial => 'get_producer_consumer'
  end

end
