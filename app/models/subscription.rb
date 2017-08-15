class Subscription
  include Taggable
  
  def initialize(user)
    @user = user
  end

  def tags
    @user.watched
  end

  def drop_tags(ids)
    TagSubscription.where('user_id = ? AND tag_id IN (?)', @user.id, ids).delete_all
  end
  
  def tags_changed
    @user.update_index(defer: false)
  end
  
  def save
    @user.save
  end
end

