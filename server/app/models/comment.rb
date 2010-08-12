class Comment < ActiveRecord::Base
  acts_as_authorizable
  named_scope :def_scope
  belongs_to :commentable, :polymorphic => true
  belongs_to :user, :foreign_key => 'user_id', :class_name => 'Account'
  
  # NOTE: install the acts_as_votable plugin if you 
  # want user to vote on the quality of comments.
  #acts_as_voteable
  
  # NOTE: Comments belong to a user
  belongs_to :account, :foreign_key => 'user_id'

  def self.default_search_attribute
    'comment'
  end

  def self.default_includes
    # The default display index_row columns
    return [:account]
  end
  
  # Helper class method to lookup all comments assigned
  # to all commentable types for a given user.
  def self.find_comments_by_user(account)
    find(:all,
      :conditions => ["user_id = ?", account.id],
      :order => "created_at DESC"
    )
  end
  
  # Helper class method to look up all comments for 
  # commentable class name and commentable id.
  def self.find_comments_for_commentable(commentable_str, commentable_id)
    find(:all,
      :conditions => ["commentable_type = ? and commentable_id = ?", commentable_str, commentable_id],
      :order => "created_at DESC"
    )
  end

  # Helper class method to look up a commentable object
  # given the commentable class name and id 
  def self.find_commentable(commentable_str, commentable_id)
    commentable_str.constantize.find(commentable_id)
  end
end
