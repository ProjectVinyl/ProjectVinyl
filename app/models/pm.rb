class Pm < ApplicationRecord
  include Counterable

  belongs_to :user

  belongs_to :receiver, class_name: 'User'
  belongs_to :sender, class_name: 'User'

  belongs_to :comment_thread, dependent: :destroy
  belongs_to :new_comment, class_name: 'Comment'

  conditional_counter_cache :user, :unread_pms, :is_unread, :message_count

  STATE_NORMAL = 0
  STATE_DELETED = 1

  scope :find_for_user, ->(id, user) { includes(:comment_thread, :new_comment).where(id: id, user_id: user.id).first }
  scope :find_for_tab_counter, ->(type, user) {
    listing_selector = where(user_id: user.id, state: type == 'deleted' ? STATE_DELETED : STATE_NORMAL)
    return listing_selector.where(receiver: user) if type == 'received'
    return listing_selector.where(sender: user) if type == 'sent'
    return listing_selector.where(unread: true) if type == 'new'
    listing_selector
  }

  scope :find_for_tab, ->(type, user) {
    joins("LEFT JOIN comment_threads ON comment_threads.id = pms.comment_thread_id AND comment_threads.owner_type = 'Pm'")
      .select('pms.*').includes(:comment_thread, :sender, new_comment: [:direct_user])
      .find_for_tab_counter(type, user)
      .order('comment_threads.created_at DESC')
  }

  def is_unread
    state == STATE_NORMAL && unread
  end

  def self.send_pm(sender, receivers, subject, message)
    Pm.transaction do
      pm = Pm.create(user: sender, sender: sender, receiver: receivers.first, unread: false)
      thread = pm.comment_thread.create(
        title: subject.present? ? subject : '[No Subject]',
        user: sender,
        owner: pm,
        total_comments: 1
      )
      comment = thread.comments.create(user_id: sender.id, bbc_content: message)
      pm.new_comment_id = comment.id
      pm.save

      receivers = receivers - [sender]

      recievers.each do |receiver|
        pms = Pm.create(
          user: receiver,
          sender: sender,
          receiver: receiver,
          unread: true,
          comment_thread: thread,
          new_comment: comment
        )
        pms.send_delivery_notification
      end

      return pm
    end
  end

  def comment_posted(comment)
    Pm.where(state: STATE_NORMAL, unread: false, comment_thread_id: comment_thread_id)
      .where.not(user_id: comment.user_id)
      .update_all(new_comment_id: comment.id, unread: true)
    Pm.where(state: STATE_NORMAL, comment_thread_id: comment_thread_id)
      .where.not(user_id: comment.user_id)
      .find_each{|t| t.send_reply_notification(comment) }
  end

  def get_tab_type(user)
    if self.state == STATE_NORMAL
      return self.sender_id == user.id ? 'sent' : 'received'
    end
    'deleted'
  end

  def last_comment
    new_comment
  end

  def location
    if self.unread && self.new_comment_id
      return "#{link}#comment_#{Comment.encode_open_id(new_comment_id)}"
    end
    link
  end

  def link
    "/messages/#{self.id}"
  end

  def toggle_deleted
    if self.state == STATE_NORMAL
      self.unread = false
      self.state = STATE_DELETED
    else
      self.state = STATE_NORMAL
    end
    self.save
  end

  def send_reply_notification(reply)
    Notification.send_to(
      [user_id, sender_id],
      notification_params: {
        message: "#{reply.user.username} has posted a reply to your Private Message",
        location: location,
        originator: comment_thread
      },
      toast_params: {
        title: "@#{reply.user.username} replied to your message",
        params: reply.toast_params
    })
  end

  def send_delivery_notification
    Notification.send_to(
      [receiver_id] - [sender_id],
      notification_params: {
        message: "#{sender.username} has sent you a Private Message: <b>#{comment_thread.title}</b>",
        location: location,
        originator: self
      },
      toast_params: {
        title: "@#{user.username} send you a Private Message",
        params: {
          badge: '/favicon.ico',
          icon: user.avatar,
          body: comment_thread.title
        }
    })
  end
end
