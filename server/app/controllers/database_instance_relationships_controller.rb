class DatabaseInstanceRelationshipsController < ApplicationController
  # GET /database_instance_relationships
  # GET /database_instance_relationships.xml
  def index
    sort = case params['sort']
           when "name" then "database_instance_relationships.name"
           when "name_reverse" then "database_instance_relationships.name DESC"
           when "assigned_at" then "database_instance_relationships.assigned_at"
           when "assigned_at_reverse" then "database_instance_relationships.assigned_at DESC"
           end
    
    # if a sort was not defined we'll make one default
    if sort.nil?
      params['sort'] = DatabaseInstanceRelationship.default_search_attribute
      sort = 'database_instance_relationships.' + DatabaseInstanceRelationship.default_search_attribute
    end
    
    # XML doesn't get pagination
    if params[:format] && params[:format] == 'xml'
      @objects = DatabaseInstanceRelationship.find(:all, :order => sort)
    else
      @objects = DatabaseInstanceRelationship.paginate(:all,
                                                       :order => sort,
                                                       :page => params[:page])
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @objects.to_xml(:dasherize => false) }
    end
  end
  
  

  # GET /database_instance_relationships/1
  # GET /database_instance_relationships/1.xml
  def show
    @database_instance_relationship = DatabaseInstanceRelationship.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @database_instance_relationship.to_xml(:dasherize => false) }
    end
  end

  # GET /database_instance_relationships/new
  def new
    @database_instance_relationship = DatabaseInstanceRelationship.new
  end

  # GET /database_instance_relationships/1/edit
  def edit
    @database_instance_relationship = DatabaseInstanceRelationship.find(params[:id])
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
    @database_instance_relationship = DatabaseInstanceRelationship.find(params[:id])

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
    @database_instance_relationship = DatabaseInstanceRelationship.find(params[:id])
    @database_instance_relationship.destroy

    respond_to do |format|
      format.html { redirect_to database_instance_relationships_url }
      format.xml  { head :ok }
    end
  end
  
  # GET /database_instance_relationships/1/version_history
  def version_history
    @database_instance_relationship = DatabaseInstanceRelationship.find_with_deleted(params[:id])
    render :action => "version_table", :layout => false
  end
  
end
