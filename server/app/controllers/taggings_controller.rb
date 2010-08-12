class TaggingsController < ApplicationController
  # sets the @auth object and @object
  before_filter :get_obj_auth
  before_filter :modelperms

  # GET /taggings
  # GET /taggings.xml
  def index
    special_joins = {}
    ## BUILD MASTER HASH WITH ALL SUB-PARAMS ##
    allparams = {}
    allparams[:mainmodel] = Tagging
    allparams[:webparams] = params
    allparams[:special_joins] = special_joins

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

  # GET /taggings/1
  # GET /taggings/1.xml
  def show
    @tagging = @object

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @tagging.to_xml(:dasherize => false) }
    end
  end

  # GET /taggings/new
  def new
    @tagging = @object
  end

  # GET /taggings/1/edit
  def edit
    @tagging = @object
  end

  # POST /taggings
  # POST /taggings.xml
  def create
    @tagging = Tagging.new(params[:tagging])
    tag = Tag.find(params[:tagging][:tag_id])
    return unless filter_perms(@auth,tag,['updater'])
    taggable_model = params[:tagging][:taggable_type].constantize
    taggable = taggable_model.find(params[:tagging][:taggable_id])
    return unless filter_perms(@auth,taggable,['updater'])

    respond_to do |format|
      if @tagging.save
        
        format.html { 
          flash[:notice] = 'Tagging was successfully created.'
          redirect_to tagging_url(@tagging) 
        }
        format.js { 
          if params[:refcontroller]
            refcontroller = params[:refcontroller]
            if refcontroller == 'node_groups'
              render(:update) { |page| page.replace_html params[:div], :partial => params['partial'], :locals => { :tags => @tagging.taggable.tags } } if params[:div] && params[:partial]
            elsif refcontroller == 'tags'
              render(:update) { |page| page.replace_html params[:div], :partial => params['partial'], :locals => { :tag => @tagging.tag } } if params[:div] && params[:partial]
            end
          end
        }
        format.xml  { head :created, :location => tagging_url(@tagging) }
      else
        format.html { render :action => "new" }
        format.js   { render(:update) { |page| page.alert(@tagging.errors.full_messages) } }
        format.xml  { render :xml => @tagging.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /taggings/1
  # PUT /taggings/1.xml
  def update
    @tagging = @object
    tag = @tagging.tag
    return unless filter_perms(@auth,tag,['updater'])
    taggable = @tagging.taggable
    return unless filter_perms(@auth,taggable,['updater'])

    respond_to do |format|
      if @tagging.update_attributes(params[:tagging])
        flash[:notice] = 'Tagging was successfully updated.'
        format.html { redirect_to tagging_url(@tagging) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @tagging.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /taggings/1
  # DELETE /taggings/1.xml
  def destroy
    @tagging = @object
    tag = @tagging.tag
    return unless filter_perms(@auth,tag,['updater'])
    taggable = @tagging.taggable
    return unless filter_perms(@auth,taggable,['updater'])
    
    begin
      @tagging.destroy
    rescue Exception => destroy_error
      respond_to do |format|
        format.html { 
          flash[:error] = destroy_error.message
          redirect_to tagging_url(@tagging) and return
        }
        format.js   { render(:update) { |page| page.alert(destroy_error.message) } }
        format.xml  { head :error } # FIXME?
      end
      return
    end
    
    # Success!
    respond_to do |format|
      format.html { redirect_to taggings_url }
      format.js {
        render(:update) { |page| page.replace_html 'taggings', {:partial => 'tags/taggings', :locals => { :tag => @tagging.tag} } }
      }
      format.xml  { head :ok }
    end
  end
  
  # GET /taggings/1/version_history
  def version_history
    @tagging = Tagging.find(params[:id])
    render :action => "version_table", :layout => false
  end
  
end
