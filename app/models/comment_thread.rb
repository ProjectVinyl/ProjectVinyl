class CommentThread < ApplicationRecord
  include Indirected
  include UserCachable

  has_many :comments, dependent: :destroy, counter_cache: "total_comments"
  has_many :thread_subscriptions, dependent: :destroy
  has_many :subscribers, through: :thread_subscriptions, class_name: 'User'

  belongs_to :owner, polymorphic: true

  def private_message?
    self.owner_type == 'Pm'
  end

  def video?
    self.owner_type == 'Video'
  end

  def board?
    self.owner_type == 'Board'
  end

  def contributing?(user)
    !private_message? || (Pm.where('comment_thread_id = ? AND (sender_id = ? OR receiver_id = ?)', self.id, user.id, user.id).count > 0)
  end

  def get_title
    self.title || "Untitled"
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

  def get_comments(user)
    Rails.cache.fetch(cache_key_with_user(user), expires_in: 1.hour) do
      result = comments.includes(direct_user: [user_badges: [:badge]]).includes(:mentions).order(:created_at)
      if user && (user == true || user.is_contributor?)
        return result
      end
      result.where(hidden: false)
    end
  end

  def description
    ""
  end

  def link
    if self.board? && !self.owner.nil?
      return "/#{self.owner.short_name}/#{self.id}-#{self.safe_title}"
    end
    "/forum/threads/#{self.id}-#{self.safe_title}"
  end

  def location
    return owner.location if self.private_message?
    return owner.link if self.video?
    return link if !self.owner

    "#{owner.link}/#{self.id}-#{self.safe_title}"
  end

  def icon
    return self.owner.thumb if self.video?
    user.avatar
  end

  def preview
    return self.owner.title if self.video?
    last_comment.preview
  end

  def subscribed?(user)
    user && (self.thread_subscriptions.where(user_id: user_id).count > 0)
  end

  def subscribe(user)
    self.thread_subscriptions.create(user_id: user_id)
  end

  def unsubscribe(user)
    self.thread_subscriptions.where(user_id: user_id).destroy_all
  end

  def toggle_subscribe(user)
    return false if !user

    if self.subscribed?(user)
      self.unsubscribe(user)
      return false
    end
    self.subscribe(user)
    true
  end

  def bump(sender, params, comment)
    if self.owner_type == 'Pm'
      return self.owner.bump(sender, params, comment)
    end

    if !sender.dummy? && sender.subscribe_on_reply? && !self.subscribed?(sender)
      self.subscribe(sender)
    end

    receivers = self.thread_subscriptions.pluck(:user_id) - [sender.id]

    Notification.notify_receivers(receivers, self,
      "#{sender.username} has posted a reply to <b>#{self.title}</b>", self.location)
  end
end
