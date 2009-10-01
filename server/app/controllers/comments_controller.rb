class CommentsController < ApplicationController
  # GET /comments
  # GET /comments.xml
  def index
    # The default display index_row columns (node_groups model only displays local table name)
    default_includes = []
    special_joins = {}

    ## BUILD MASTER HASH WITH ALL SUB-PARAMS ##
    allparams = {}
    allparams[:mainmodel] = Comment
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

  # GET /comments/1
  # GET /comments/1.xml
  def show
    includes = process_includes(Comment, params[:include])
    
    @comment = Comment.find(params[:id],
                            :include => includes)

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @comment.to_xml(:include => convert_includes(includes),
                                                   :dasherize => false) }
    end
  end

  # GET /comments/new
  def new
    @comment = Comment.new
  end

  # GET /comments/1/edit
  def edit
    @comment = Comment.find(params[:id])
  end

  # GET /comments/field_names
  def field_names
    super(Comment)
  end

  # POST /comments
  # POST /comments.xml
  def create
    params[:comment][:user_id] = current_user.id
    if params[:comment][:commentable_type].eql?('Node')
      mailer_params = {}
      mailer_params[:nodename] = Node.find(params[:comment][:commentable_id]).name
      mailer_params[:username] = current_user.name
      mailer_params[:changetype] = 'comment'
      mailer_params[:changevalue] = params[:comment][:comment]
      mailer_params[:time] = Time.now
      Mailer.deliver_notify_node_new($users_email, mailer_params)
    end
    @comment = Comment.new(params[:comment])

    respond_to do |format|
      if @comment.save
        flash[:notice] = 'Comment was successfully created.'
        format.html { redirect_to comment_url(@comment) }
        format.js { 
          render(:update) { |page|
            page.replace_html 'comments', :partial => 'shared/comments', :locals => { :object => @comment.commentable }
            #page.hide 'create_node_group_assignment'
            #page.show 'add_node_group_assignment_link'
          }
        }
        format.xml  { head :created, :location => comment_url(@comment) }
      else
        format.html { render :action => "new" }
        format.js   { render(:update) { |page| page.alert(@comment.errors.full_messages) } }
        format.xml  { render :xml => @comment.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /comments/1
  # PUT /comments/1.xml
  def update
    @comment = Comment.find(params[:id])

    respond_to do |format|
      if @comment.update_attributes(params[:comment])
        flash[:notice] = 'Comment was successfully updated.'
        format.html { redirect_to comment_url(@comment) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @comment.errors.to_xml, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /comments/1
  # DELETE /comments/1.xml
  def destroy
    @comment = Comment.find(params[:id])
    @comment.destroy

    respond_to do |format|
      format.html { redirect_to comments_url }
      format.xml  { head :ok }
    end
  end
  
end
