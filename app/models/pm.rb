class Pm < ApplicationRecord
  belongs_to :receiver, class_name: 'User'
  belongs_to :sender, class_name: 'User'

  belongs_to :comment_thread, dependent: :destroy
  belongs_to :new_comment, class_name: 'Comment'
  
  scope :find_for_user, ->(id, user) { includes(:comment_thread, :new_comment).where('`pms`.id = ? AND `pms`.user_id = ?', id, user.id).first }
  
  scope :find_for_tab_counter, ->(type, user) {
    listing_selector = where(user_id: user.id, state: type == 'deleted' ? 1 : 0)
    if type == 'received'
      return listing_selector.where(receiver: user)
    elsif type == 'sent'
      return listing_selector.where(sender: user)
    elsif type == 'new'
      return listing_selector.where(unread: true)
    end
    listing_selector
  }
  
  scope :find_for_tab, ->(type, user) {
    joins('LEFT JOIN `comment_threads` ON `comment_threads`.id = `pms`.comment_thread_id AND `comment_threads`.owner_type = "Pm"')
      .select('`pms`.*').includes(:comment_thread, :sender, new_comment: [:direct_user])
      .find_for_tab_counter(type, user)
      .order('`comment_threads`.created_at DESC')
  }

  def self.send_pm(sender, receiver, subject, message)
    Pm.transaction do
      pm = Pm.create(user_id: sender.id, sender: sender, receiver: receiver, unread: false)
      thread = CommentThread.create(user: sender, owner: pm, total_comments: 1)
      thread.set_title(subject.present? ? subject : '[No Subject]')
      comment = thread.comments.create(user_id: sender.id)
      comment.update_comment(message)
      pm.comment_thread_id = thread.id
      pm.new_comment_id = comment.id
      pm.save
      if sender.id != receiver.id
        pms = Pm.create(
          user_id: receiver.id,
          sender: sender,
          receiver: receiver,
          unread: true,
          comment_thread_id: thread.id,
          new_comment_id: comment.id
        )
        Notification.notify_recievers([receiver.id], pms,
          "#{sender.username} has sent you a Private Message: <b>#{thread.title}</b>", pms.location)
      end
      return pm
    end
  end

  def bump(sender, comment)
    Pm.where('state = 0 AND unread = false AND comment_thread_id = ? AND NOT user_id = ?', self.comment_thread_id, sender.id).update_all(new_comment_id: comment.id, unread: true)
    Pm.where('state = 0 AND comment_thread_id = ? AND NOT user_id = ?', self.comment_thread_id, sender.id).find_each do |t|
      Notification.notify_recievers([t.user_id], self, sender.username + " has posted a reply on <b>" + self.comment_thread.title + "</b>", t.location)
    end
  end
  
  def get_tab_type(user)
    if self.state == 0
      return 'sent' if self.sender_id == user.id
      return 'received'
    end
    'deleted'
  end

  def last_comment
    new_comment
  end

  def location
    result = "/message/#{self.id}"
    if self.unread && self.new_comment_id
      result += "/message/#{self.id}#comment_#{Comment.encode_open_id(self.new_comment_id)}"
    end
    result
  end

  def toggle_deleted
    if self.state == 0
      if self.unread
        self.unread = false
      end
      self.state = 1
    else
      self.state = 0
    end
    self.save
  end
end
