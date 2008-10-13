class CommentsController < ApplicationController
  # GET /comments
  # GET /comments.xml
  def index
    includes = process_includes(Comment, params[:include])
    
    sort = case params['sort']
           when "created_at" then "comments.created_at"
           when "created_at_reverse" then "comments.created_at DESC"
           when "account" then "comments.user_id"
           when "account_reverse" then "comments.user_id DESC"
           when "belongs_to" then "comments.commentable_type, comments.commentable_id"
           when "belongs_to_reverse" then "comments.commentable_type DESC, comments.commentable_id DESC"
           end
    
    # if a sort was not defined we'll make one default
    if sort.nil?
      params['sort'] = 'created_at'
      sort = 'comments.created_at'
    end
    
    # XML doesn't get pagination
    if params[:format] && params[:format] == 'xml'
      @objects = Comment.find(:all,
                              :include => includes,
                              :order => sort)
    else
      @objects = Comment.paginate(:all,
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

  # POST /comments
  # POST /comments.xml
  def create
    params[:comment][:user_id] = current_user.id
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
