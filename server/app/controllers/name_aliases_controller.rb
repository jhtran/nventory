class NameAliasesController < ApplicationController
  # sets the @auth object and @object
  before_filter :get_obj_auth
  before_filter :modelperms

  # GET /name_aliases
  # GET /name_aliases.xml
  def index
    ## BUILD MASTER HASH WITH ALL SUB-PARAMS ##
    allparams = {}
    allparams[:mainmodel] = NameAlias
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

  # GET /name_aliases/1
  # GET /name_aliases/1.xml
  def show
    @name_alias = @object

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @name_alias.to_xml(:include => convert_includes(includes),
                                               :dasherize => false) }
    end
  end

  # GET /name_aliases/new
  def new
    @models = []
    list_models.each {|model| @models << model if (model != 'NameAlias') && (model.constantize.default_search_attribute == "name")}
    @models = @models.sort.uniq
    @name_alias = @object
  end

  # GET /name_aliases/1/edit
  def edit
    @models = []
    list_models.each {|model| @models << model if (model != 'NameAlias') && (model.constantize.default_search_attribute == "name")}
    @models = @models.sort.uniq
    @name_alias = @object
  end

  # POST /name_aliases
  # POST /name_aliases.xml
  def create
    model = params[:name_alias][:source_type].constantize
    obj = model.find(params[:name_alias][:source_id])
    return unless filter_perms(@auth,obj,['updater'])
    @name_alias = NameAlias.new(params[:name_alias])

    respond_to do |format|
      if @name_alias.save
        flash[:notice] = 'name_alias was successfully created.'
        format.html { redirect_to name_alias_url(@name_alias) }
        format.js {
          render(:update) { |page|
            if request.env["HTTP_REFERER"].include? "nodes"
              page.replace_html 'name_aliases', :partial => 'nodes/name_aliases', :locals => { :node => @name_alias.source }
              page.hide 'create_name_alias'
              page.show 'add_name_alias_link'
            end
          }
        }
        format.xml  { head :created, :location => name_alias_url(@name_alias) }
      else
        format.html { render :action => "new" }
        format.js   { render(:update) { |page| page.alert(@name_alias.errors.full_messages) } }
        format.xml  { render :xml => @name_alias.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /name_aliases/1
  # PUT /name_aliases/1.xml
  def update
    @name_alias = @object
    return unless filter_perms(@auth,@name_alias.source,['updater'])

    respond_to do |format|
      if @name_alias.update_attributes(params[:name_alias])
        flash[:notice] = 'name_alias was successfully updated.'
        format.html { redirect_to name_alias_url(@name_alias) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @name_alias.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /name_aliases/1
  # DELETE /name_aliases/1.xml
  def destroy
    @name_alias = @object
    return unless filter_perms(@auth,@name_alias.source,['updater'])
    @name_alias.destroy

    respond_to do |format|
      format.html { redirect_to name_aliases_url }
      format.xml  { head :ok }
    end
  end
  
  # GET /name_aliases/1/version_history
  def version_history
    @name_alias = NameAlias.find(params[:id])
    render :action => "version_table", :layout => false
  end
  
  # GET /name_aliases/field_names
  def field_names
    super(NameAlias)
  end

  # GET /name_aliases/search
  def search
    @name_alias = NameAlias.find(:first)
    render :action => 'search'
  end

  def get_sources
    source_type = request.raw_post
    unless source_type.blank? || source_type.nil?
      @model = source_type.gsub(/&_=*/,'').constantize
      @allobjects = @model.find(:all, :select => "id, name", :order => "name").collect{|a| [a.name,a.id]}
    else
      @model = ""
      @allobjects = ""
    end
    render :partial => 'get_sources'
  end
  
end
