class DatabaseInstancesController < ApplicationController
  # sets the @auth object and @object
  before_filter :get_obj_auth
  before_filter :modelperms

  # GET /database_instances
  # GET /database_instances.xml
  def index
    ## BUILD MASTER HASH WITH ALL SUB-PARAMS ##
    allparams = {}
    allparams[:mainmodel] = DatabaseInstance
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

  # GET /database_instances/1
  # GET /database_instances/1.xml
  def show
    @database_instance = @object

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @database_instance.to_xml(:include => convert_includes(includes),
                                                             :dasherize => false) }
    end
  end

  # GET /database_instances/new
  def new
    @database_instance = @object
    respond_to do |format|
      format.html # show.html.erb
      format.js  { render :action => "inline_new", :layout => false }
    end
  end

  # GET /database_instances/1/edit
  def edit
    @database_instance = @object
  end

  # POST /database_instances
  # POST /database_instances.xml
  def create
    @database_instance = DatabaseInstance.new(params[:database_instance])

    respond_to do |format|
      if @database_instance.save
        format.html { 
          flash[:notice] = 'Database Instance was successfully created.'
          redirect_to database_instance_url(@database_instance) 
        }
        format.js { 
          render(:update) { |page| 
            page.replace_html 'create_database_instance_assignment', :partial => 'shared/create_assignment', :locals => { :from => 'node', :to => 'database_instance' }
            page['node_database_instance_assignment_database_instance_id'].value = @database_instance.id
            page.hide 'new_database_instance'
            
            # WORKAROUND: We have to manually escape the single quotes here due to a bug in rails:
            # http://dev.rubyonrails.org/ticket/5751
            page.visual_effect :highlight, 'create_database_instance_assignment', :startcolor => "\'"+RELATIONSHIP_HIGHLIGHT_START_COLOR+"\'", :endcolor => "\'"+RELATIONSHIP_HIGHLIGHT_END_COLOR+"\'", :restorecolor => "\'"+RELATIONSHIP_HIGHLIGHT_RESTORE_COLOR+"\'"
          }
        }
        format.xml  { head :created, :location => database_instance_url(@database_instance) }
      else
        format.html { render :action => "new" }
        format.js   { render(:update) { |page| page.alert(@database_instance.errors.full_messages) } }
        format.xml  { render :xml => @database_instance.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /database_instances/1
  # PUT /database_instances/1.xml
  def update
    @database_instance = @object

    respond_to do |format|
      if @database_instance.update_attributes(params[:database_instance])
        flash[:notice] = 'DatabaseInstance was successfully updated.'
        format.html { redirect_to database_instance_url(@database_instance) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @database_instance.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /database_instances/1
  # DELETE /database_instances/1.xml
  def destroy
    @database_instance = @object
    @database_instance.destroy

    respond_to do |format|
      format.html { redirect_to database_instances_url }
      format.xml  { head :ok }
    end
  end
  
  # GET /database_instances/1/version_history
  def version_history
    @database_instance = DatabaseInstance.find(params[:id])
    render :action => "version_table", :layout => false
  end
  
  # GET /database_instances/field_names
  def field_names
    super(DatabaseInstance)
  end

  # GET /database_instances/search
  def search
    @database_instance = DatabaseInstance.find(:first)
    render :action => 'search'
  end
  
end
