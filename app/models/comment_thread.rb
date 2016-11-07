class CommentThread < ActiveRecord::Base
  belongs_to :direct_user, class_name: "User", foreign_key: "user_id"
  
  has_many :comments, dependent: :destroy, counter_cache: "total_comments"
  has_many :thread_subscriptions, dependent: :destroy
  has_many :subscribers, :through => :thread_subscriptions, class_name: 'User'
  
  belongs_to :owner, polymorphic: true
  
  def user
    return self.direct_user || @dummy || (@dummy = User.dummy(self.user_id))
  end
  
  def user=(user)
    self.direct_user = user
  end
  
  def get_title
    return self.title && self.title.length > 0 ? self.title : "Untitled"
  end
  
  def set_title(name)
    name = ApplicationHelper.check_and_trunk(name, self.title)
    self.title = name
    self.safe_title = ApplicationHelper.url_safe(name)
    self.save
  end
  
  def get_comments(all)
    if all
      return comments.includes(:direct_user, :mentions)
    end
    return comments.where(hidden: false).includes(:direct_user, :mentions)
  end
  
  def location
    if self.owner_type == 'Video'
      return '/view/' + self.owner_id.to_s
    end
    if self.owner_type == 'Report'
      return '/admin/report/view/' + self.owner_id.to_s
    end
    return '/thread/' + self.id.to_s
  end
  
  def subscribed?(user)
    return user && (self.thread_subscriptions.where(user_id: user.id).length > 0)
  end
  
  def subscribe(user)
    self.thread_subscriptions.create(user_id: user.id)
  end
  
  def unsubscribe(user)
    self.thread_subscriptions.where('user_id = ?', user.id).destroy_all
  end
  
  def toggleSubscribe(user)
    if !user
      return false
    end
    if self.subscribed?(user)
      self.unsubscribe(user)
      return false
    end
    self.subscribe(user)
    return true
  end
end
