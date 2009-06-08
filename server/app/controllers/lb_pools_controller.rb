class LbPoolsController < ApplicationController
  # GET /lb_pools
  # GET /lb_pools.xml
  def index
    # The default display index_row columns (lb_pools model only displays local table name)
    default_includes = []
    special_joins = {}

    ## BUILD MASTER HASH WITH ALL SUB-PARAMS ##
    allparams = {}
    allparams[:mainmodel] = LbPool
    params['sort'] = "node_group" if ( params['sort'].nil? || params['sort'] == "name" )
    params['sort'] = "node_group_reverse" if ( params['sort'].nil? || params['sort'] == "name_reverse" )
    allparams[:webparams] = params
    allparams[:default_includes] = default_includes
    allparams[:special_joins] = special_joins

    results = SearchController.new.search(allparams)
    flash[:error] = results[:errors].join('<br />') unless results[:errors].empty?
    includes = results[:includes]
    @objects = results[:search_results]
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @objects.to_xml(:include => convert_includes(includes),
                                                   :dasherize => false) }
    end
  end

  # GET /lb_pools/1
  # GET /lb_pools/1.xml
  def show
    includes = process_includes(LbPool, params[:include])
    @lb_pool = LbPool.find(params[:id], :include => includes)

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @lb_pool.to_xml(:include => convert_includes(includes),
                                                      :dasherize => false) }
    end
  end

  # GET /lb_pools/new
  def new
    @lb_pool = LbPool.new
    respond_to do |format|
      format.html # show.html.erb
      format.js  { render :action => "inline_new", :layout => false }
    end
  end

  # GET /lb_pools/1/edit
  def edit
    @lb_pool = LbPool.find(params[:id])
  end

  # POST /lb_pools
  # POST /lb_pools.xml
  def create
    @lb_pool = LbPool.new(params[:lb_pool])
    
    respond_to do |format|
      if @lb_pool.save 
        flash[:notice] = 'Load Balancer Pool was successfully created.'
        format.html { redirect_to lb_pool_url(@lb_pool) }
        format.xml  { head :created, :location => lb_pool_url(@lb_pool) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @lb_pool.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /lb_pools/1
  # PUT /lb_pools/1.xml
  def update
    @lb_pool = LbPool.find(params[:id])
    respond_to do |format|
      if @lb_pool.update_attributes(params[:lb_pool])
        flash[:notice] = 'Load Balancer Service Pool was successfully updated.'
        format.html { redirect_to lb_pool_url(@lb_pool) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @lb_pool.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /lb_pools/1
  # DELETE /lb_pools/1.xml
  def destroy
    @lb_pool = LbPool.find(params[:id])
    @lb_pool.destroy

    respond_to do |format|
      format.html { redirect_to lb_pools_url }
      format.xml  { head :ok }
    end
  end
  
  # GET /lb_pools/1/version_history
  def version_history
    @lb_pool = LbPool.find(params[:id])
    render :action => "version_table", :layout => false
  end
  
  # GET /lb_pools/field_names
  def field_names
    super(LbPool)
  end

  # GET /lb_pools/search
  def search
    @lb_pool = LbPool.find(:first)
    render :action => 'search'
  end
  
end
