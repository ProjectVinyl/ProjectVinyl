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

  def pagination(current_user, page: -1, reverse: false, page_size: 10, user_is_contributor: false, expires_in: 1.hour)
    Rails.cache.fetch(cache_key_with_user(user, page, reverse, page_size, user_is_contributor), expires_in: expires_in) do
      Pagination.paginate(comments_for_pagination(current_user, user_is_contributor: user_is_contributor),
        page, page_size, reverse
      )
    end
  end

  def comments_for_pagination(current_user, user_is_contributor: false)
    result = comments
            .includes(direct_user: [user_badges: [:badge]])
            .includes(:mentions)
            .order(:created_at)
    return result.with_likes(current_user) if user && (user_is_contributor || user.is_contributor?)
    result.where(hidden: false).with_likes(current_user)
  end

  def description
    ""
  end

  def link
    return "/forums/#{owner.short_name}/#{id}" if board? && !owner.nil?
    "/forums/threads/#{id}-#{safe_title}"
  end

  def location
    return owner.location if private_message?
    return owner.link if video?
    return link if !owner

    "#{owner.link}/#{id}"
  end

  def icon
    return owner.thumb if video?
    user.avatar
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

  def comment_posted(comment)
    subscribe(comment.user) if !private_message? && !comment.user.dummy? && comment.user.subscribe_on_reply? && !subscribed?(comment.user)
    return owner.comment_posted(comment) if owner.respond_to?(:comment_posted)
    send_reply_notification(comment)
  end

  def send_reply_notification(comment)
    Notification.send_to(
      (thread_subscriptions.pluck(:user_id) - [comment.user_id]),
      notification_params: {
        message: "#{comment.user.username} has posted a reply to <b>#{title}</b>",
        location: location,
        originator: self
      },
      toast_params: {
        title: "@#{comment.user.username} posted on <b>#{title}</b>",
        params: comment.toast_params
      })
  end
end
