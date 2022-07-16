class CommentThread < ApplicationRecord
  include Indirected
  include UserCachable
  include Titled

  has_many :comments, dependent: :destroy, counter_cache: "total_comments"
  has_many :thread_subscriptions, dependent: :destroy
  has_many :subscribers, through: :thread_subscriptions, class_name: 'User'

  belongs_to :owner, polymorphic: true

  def private_message?
    owner_type == 'Pm'
  end

  def video?
    owner_type == 'Video'
  end

  def board?
    owner_type == 'Board'
  end

  def contributing?(user)
    !private_message? || (Pm.where('comment_thread_id = ? AND (sender_id = ? OR receiver_id = ?)', id, user.id, user.id).count > 0)
  end

  def last_comment
    @last_comment || @last_comment = comments.order(:created_at, :updated_at).reverse_order.limit(1).first
  end

  def get_comments(user)
    Rails.cache.fetch(cache_key_with_user(user), expires_in: 1.hour) do
      result = comments.includes(direct_user: [user_badges: [:badge]]).includes(:mentions).order(:created_at)
      return result if user && (user == true || user.is_contributor?)
      result.where(hidden: false)
    end
  end

  def description
    ""
  end

  def link
    return "/#{owner.short_name}/#{id}-#{safe_title}" if board? && !owner.nil?
    "/forum/threads/#{id}-#{safe_title}"
  end

  def location
    return owner.location if private_message?
    return owner.link if video?
    return link if !owner

    "#{owner.link}/#{id}-#{safe_title}"
  end

  def icon
    return owner.thumb if video?
    user.avatar
  end

  def preview
    return owner.description if video?
    last_comment.preview
  end

  def subscribed?(user)
    user && (thread_subscriptions.where(user_id: user_id).count > 0)
  end

  def subscribe(user)
    thread_subscriptions.create(user_id: user_id)
  end

  def unsubscribe(user)
    thread_subscriptions.where(user_id: user_id).destroy_all
  end

  def toggle_subscribe(user)
    return false if !user

    if subscribed?(user)
      unsubscribe(user)
      return false
    end
    subscribe(user)
    true
  end

  def bump(sender, params, comment)
    return owner.bump(sender, params, comment) if private_message?
    subscribe(sender) if !sender.dummy? && sender.subscribe_on_reply? && !subscribed?(sender)
    return owner.bump(sender, params, comment) if video?

    Notification.send_to(
      (thread_subscriptions.pluck(:user_id) - [sender.id]),
      notification_params: {
        message: "#{sender.username} has posted a reply to <b>#{title}</b>",
        location: location,
        originator: self
      },
      toast_params: {
        title: "@#{user.username} replied to <b>#{title}</b>",
        params: {
          badge: '/favicon.ico',
          icon: user.avatar,
          body: comment.preview
        }
      })
  end
end
