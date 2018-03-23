class CommentThread < ApplicationRecord
  include Indirected

  has_many :comments, dependent: :destroy, counter_cache: "total_comments"
  has_many :thread_subscriptions, dependent: :destroy
  has_many :subscribers, through: :thread_subscriptions, class_name: 'User'

  belongs_to :owner, polymorphic: true
  
  def private_message?
    self.owner_type == 'Pm'
  end

  def contributing?(user)
    !private_message? || (Pm.where('comment_thread_id = ? AND (sender_id = ? OR receiver_id = ?)', self.id, user.id, user.id).count > 0)
  end

  def get_title
    self.title.present? ? self.title : "Untitled"
  end

  def set_title(name)
    name = StringsHelper.check_and_trunk(name, self.title)
    self.title = name
    self.safe_title = PathHelper.url_safe(name)
    self.save
  end

  def last_comment
    @last_comment || @last_comment = comments.order(:created_at, :updated_at).reverse_order.limit(1).first
  end

  def get_comments(all)
    result = comments.includes(direct_user: [user_badges: [:badge]]).includes(:mentions)
    if all
      return result
    end
    result.where(hidden: false)
  end

  def description
    ""
  end

  def link
    "/thread/#{self.id}-#{self.safe_title}"
  end
  
  def location
    if self.owner_type == 'Video'
      return "/videos/#{self.owner_id}"
    end
    if self.owner_type == 'Report'
      return "/admin/report/#{self.owner_id}"
    end
    if self.owner_type == 'Pm'
      return "/message/#{self.id}"
    end
    
    "/thread/#{self.id}"
  end

  def subscribed?(user)
    user && (self.thread_subscriptions.where(user_id: user.id).count > 0)
  end

  def subscribe(user)
    self.thread_subscriptions.create(user_id: user.id)
  end

  def unsubscribe(user)
    self.thread_subscriptions.where('user_id = ?', user.id).destroy_all
  end

  def toggle_subscribe(user)
    if !user
      return false
    end
    if self.subscribed?(user)
      self.unsubscribe(user)
      return false
    end
    self.subscribe(user)
    true
  end

  def bump(sender, params, comment)
    
    if self.owner_type == 'Report'
      return self.owner.bump(self, params, comment)
    elsif self.owner_type == 'Pm'
      return self.owner.bump(sender, params, comment)
    end
    
    if !sender.is_dummy && sender.subscribe_on_reply? && !self.subscribed?(sender)
      self.subscribe(sender)
    end
    
    receivers = self.thread_subscriptions.pluck(:user_id) - [sender.id]
    
    Notification.notify_receivers(receivers, self,
      "#{sender.username} has posted a reply to <b>#{self.title}</b>", self.location)
  end
end
