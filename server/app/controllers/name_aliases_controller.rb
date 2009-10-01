class NameAliasesController < ApplicationController
  # GET /name_aliases
  # GET /name_aliases.xml
  def index
    includes = process_includes(NameAlias, params[:include])
    
    sort = case params['sort']
           when "name" then "name_aliases.name"
           when "name_reverse" then "name_aliases.name DESC"
           end
    
    # if a sort was not defined we'll make one default
    if sort.nil?
      params['sort'] = NameAlias.default_search_attribute
      sort = 'name_aliases.' + NameAlias.default_search_attribute
    end
    
    # XML doesn't get pagination
    if params[:format] && params[:format] == 'xml'
      @objects = NameAlias.find(:all,
                          :include => includes,
                          :order => sort)
    else
      @objects = NameAlias.paginate(:all,
                              :include => includes,
                              :order => sort,
                              :page => params[:page])
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @objects.to_xml(:include => convert_includes(includes),
                                                   :dasherize => false) }
    end
  end

  # GET /name_aliases/1
  # GET /name_aliases/1.xml
  def show
    includes = process_includes(NameAlias, params[:include])
    
    @name_alias = NameAlias.find(params[:id],
                    :include => includes)

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @name_alias.to_xml(:include => convert_includes(includes),
                                               :dasherize => false) }
    end
  end

  # GET /name_aliases/new
  def new
    @models = []
    ObjectSpace.each_object(Class) do |klass|
      @models << klass.to_s if (klass.ancestors.include?(ActiveRecord::Base)) && (klass.to_s !~ /(ActiveRecord|NameAlias)/) && (klass.default_search_attribute == "name")
    end
    @models = @models.sort.uniq
    @name_alias = NameAlias.new
  end

  # GET /name_aliases/1/edit
  def edit
    @models = []
    ObjectSpace.each_object(Class) do |klass|
      @models << klass.to_s if (klass.ancestors.include?(ActiveRecord::Base)) && (klass.to_s !~ /(ActiveRecord|NameAlias)/) && (klass.default_search_attribute == "name")
    end
    @models = @models.sort.uniq
    @name_alias = NameAlias.find(params[:id])
  end

  # POST /name_aliases
  # POST /name_aliases.xml
  def create
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
    @name_alias = NameAlias.find(params[:id])

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
    @name_alias = NameAlias.find(params[:id])
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
      @model = source_type.constantize
      @allobjects = @model.find(:all, :select => "id, name", :order => "name").collect{|a| [a.name,a.id]}
    else
      @model = ""
      @allobjects = ""
    end
    render :partial => 'get_sources'
  end
  
end
