class TagsController < ApplicationController
  # sets the @auth object and @object
  before_filter :get_obj_auth
  before_filter :modelperms

  # GET /tags
  # GET /tags.xml
  def index
    special_joins = {}

    ## BUILD MASTER HASH WITH ALL SUB-PARAMS ##
    allparams = {}
    allparams[:mainmodel] = Tag
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

  # GET /tags/1
  # GET /tags/1.xml
  def show
    @tag = @object

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @tag.to_xml(:include => convert_includes(includes),
                                                  :dasherize => false) }
    end
  end

  # GET /tags/new
  def new
    @tag = @object
  end

  # GET /tags/1/edit
  def edit
    @tag = @object
  end

  # POST /tags
  # POST /tags.xml
  def create
    @tag = Tag.new(params[:tag])

    respond_to do |format|
      if @tag.save
        flash[:notice] = 'Tag was successfully created.'
        format.html { redirect_to tag_url(@tag) }
        format.xml  { head :created, :location => tag_url(@tag) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @tag.errors.to_xml, :tag => :unprocessable_entity }
      end
    end
  end

  # PUT /tags/1
  # PUT /tags/1.xml
  def update
    @tag = @object

    respond_to do |format|
      if @tag.update_attributes(params[:tag])
        flash[:notice] = 'Tag was successfully updated.'
        format.html { redirect_to tag_url(@tag) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @tag.errors.to_xml, :tag => :unprocessable_entity }
      end
    end
  end

  # DELETE /tags/1
  # DELETE /tags/1.xml
  def destroy
    @tag = @object
    @tag.destroy
    flash[:error] = @tag.errors.on_base unless @tag.errors.empty?

    respond_to do |format|
      format.html { redirect_to tags_url }
      format.xml  { head :ok }
    end
  end
  
  # GET /tags/1/version_history
  def version_history
    @tag = Tag.find(params[:id])
    render :action => "version_table", :layout => false
  end
  
  # GET /tags/field_names
  def field_names
    super(Tag)
  end

  # GET /tags/search
  def search
    @tag = Tag.find(:first)
    render :action => 'search'
  end
  
end
