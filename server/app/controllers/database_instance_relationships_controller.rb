class DatabaseInstanceRelationshipsController < ApplicationController
  # sets the @auth object and @object
  before_filter :get_obj_auth
  before_filter :modelperms

  # GET /database_instance_relationships
  # GET /database_instance_relationships.xml
  def index
    ## BUILD MASTER HASH WITH ALL SUB-PARAMS ##
    allparams = {}
    allparams[:mainmodel] = DatabaseInstanceRelationship
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
  
  

  # GET /database_instance_relationships/1
  # GET /database_instance_relationships/1.xml
  def show
    @database_instance_relationship = @object

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @database_instance_relationship.to_xml(:dasherize => false) }
    end
  end

  # GET /database_instance_relationships/new
  def new
    @database_instance_relationship = @object
  end

  # GET /database_instance_relationships/1/edit
  def edit
    @database_instance_relationship = @object
  end

  # POST /database_instance_relationships
  # POST /database_instance_relationships.xml
  def create
    @database_instance_relationship = DatabaseInstanceRelationship.new(params[:database_instance_relationship])

    respond_to do |format|
      if @database_instance_relationship.save
        flash[:notice] = 'DatabaseInstanceRelationship was successfully created.'
        format.html { redirect_to database_instance_relationship_url(@database_instance_relationship) }
        format.xml  { head :created, :location => database_instance_relationship_url(@database_instance_relationship) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @database_instance_relationship.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /database_instance_relationships/1
  # PUT /database_instance_relationships/1.xml
  def update
    @database_instance_relationship = @object

    respond_to do |format|
      if @database_instance_relationship.update_attributes(params[:database_instance_relationship])
        flash[:notice] = 'DatabaseInstanceRelationship was successfully updated.'
        format.html { redirect_to database_instance_relationship_url(@database_instance_relationship) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @database_instance_relationship.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /database_instance_relationships/1
  # DELETE /database_instance_relationships/1.xml
  def destroy
    @database_instance_relationship = @object
    @database_instance_relationship.destroy

    respond_to do |format|
      format.html { redirect_to database_instance_relationships_url }
      format.xml  { head :ok }
    end
  end
  
  # GET /database_instance_relationships/1/version_history
  def version_history
    @database_instance_relationship = DatabaseInstanceRelationship.find(params[:id])
    render :action => "version_table", :layout => false
  end
  
end
