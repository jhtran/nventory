class ToolTipsController < ApplicationController
  # sets the @auth object and @object
  before_filter :get_obj_auth
  before_filter :modelperms

  # GET /tool_tips
  # GET /tool_tips.xml
  def index
    special_joins = {}

    ## BUILD MASTER HASH WITH ALL SUB-PARAMS ##
    allparams = {}
    allparams[:mainmodel] = ToolTip
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

  # GET /tool_tips/1
  # GET /tool_tips/1.xml
  def show
    @tool_tip = @object

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @tool_tip.to_xml(:include => convert_includes(includes),
                                                   :dasherize => false) }
    end
  end

  # GET /tool_tips/new
  def new
    @models = list_models
    @tool_tip = @object
  end

  # GET /tool_tips/1/edit
  def edit
    @models = list_models
    @tool_tip = @object
  end

  # GET /tool_tips/field_names
  def field_names
    super(ToolTip)
  end

  # POST /tool_tips
  # POST /tool_tips.xml
  def create
    @models = list_models
    @tool_tip = ToolTip.new(params[:tool_tip])
    respond_to do |format|
      if @tool_tip.save
        flash[:notice] = 'ToolTip was successfully created.'
        format.html { redirect_to tool_tip_url(@tool_tip) }
        format.js { 
          render(:update) { |page|
            page.replace_html 'tool_tips', :partial => 'shared/tool_tips', :locals => { :object => @tool_tip.tool_tipable }
          }
        }
        format.xml  { head :created, :location => tool_tip_url(@tool_tip) }
      else
        format.html { render :action => "new" }
        format.js   { render(:update) { |page| page.alert(@tool_tip.errors.full_messages) } }
        format.xml  { render :xml => @tool_tip.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /tool_tips/1
  # PUT /tool_tips/1.xml
  def update
    @tool_tip = @object

    respond_to do |format|
      if @tool_tip.update_attributes(params[:tool_tip])
        flash[:notice] = 'ToolTip was successfully updated.'
        format.html { redirect_to tool_tip_url(@tool_tip) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @tool_tip.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /tool_tips/1
  # DELETE /tool_tips/1.xml
  def destroy
    @tool_tip = @object
    @tool_tip.destroy

    respond_to do |format|
      format.html { redirect_to tool_tips_url }
      format.xml  { head :ok }
    end
  end

  def get_all_model_attrs(model)
    attrs = []
    unless (model.nil? || model.blank? || model == Object)
      model.column_names.each { |column| attrs << column.to_s unless (column == 'id' || column =~ /_id$/) }
      model.reflections.keys.each { |key| attrs << key.to_s }
    end
    # custom fields
    custom_fields = {}
    custom_fields[Node] = [ 'logins', 'cpu_percent', 'virtualmode', 'network_volumes', 'service_tree', 'service_parents', 'service_clients',
                            'node_group_tree', 'virtual_node_groups', 'member_through' ]
    custom_fields[NodeGroup] = [ 'virtual_nodes', 'cpu_percent', 'vips' ]
    custom_fields[NodeRack] = [ 'node_count', 'free_u_height', 'used_u_height' ]

    # add the custom fields for the model
    custom_fields[model].each { |attr| attrs << attr } if custom_fields[model]
    return attrs
  end

  def get_unused_model_attrs
    # not sure why the post is adding the '_=' string but for now ugly hack:
    @model = request.raw_post.gsub(/&_=*/,'').constantize
    @attrs = []
    all_attrs = get_all_model_attrs(@model)
    used_attrs = {}
    ToolTip.find(:all, :select => 'distinct attr', :conditions => "model = '#{@model.to_s}'").each{ |a| used_attrs[a.attr] = 1}
    all_attrs.each { |a| @attrs << a unless used_attrs[a] }
    render :partial => 'get_unused_model_attrs'
  end
  
end
