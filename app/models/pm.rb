class Pm < ActiveRecord::Base
  belongs_to :receiver, class_name: 'User'
  belongs_to :sender, class_name: 'User'

  belongs_to :comment_thread, dependent: :destroy
  belongs_to :new_comment, class_name: 'Comment'

  def self.find_for_user(id, user)
    self.eager_load(:comment_thread).includes(:new_comment).where('`pms`.id = ? AND `pms`.user_id = ?', id, user.id).first
  end

  def self.find_for_tab(type, user)
    listing_selector = self.includes(:sender).includes(new_comment: [:direct_user]).eager_load(:comment_thread).order('`comment_threads`.created_at DESC').where(user_id: user.id)
    if type == 'received'
      return listing_selector.where(state: 0, receiver: user)
    elsif type == 'sent'
      return listing_selector.where(state: 0, sender: user)
    elsif type == 'new'
      return listing_selector.where(state: 0, unread: true)
    elsif type == 'deleted'
      return listing_selector.where(state: 1)
    end
    listing_selector
  end

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
        pms = Pm.create(user_id: receiver.id, sender: sender, receiver: receiver, unread: true, comment_thread_id: thread.id, new_comment_id: comment.id)
        Notification.notify_recievers([receiver.id], pms, sender.username + " has sent you a Private Message: <b>" + thread.title + "</b>", pms.location)
      end
      return pm
    end
  end

  def bump(sender, comment)
    Pm.where('state = 0 AND unread = false AND comment_thread_id = ? AND NOT user_id = ?', self.comment_thread_id, sender.id).update_all(new_comment_id: comment.id, unread: true)
    Pm.where('state = 0 AND comment_thread_id = ? AND NOT user_id = ?', self.comment_thread_id, sender.id).find_each do |t|
      Notification.notify_recievers([t.user_id], self, sender.username + " has post a reply on <b>" + self.comment_thread.title + "</b>", t.location)
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
    result = '/message/' + self.id.to_s
    if self.unread && self.new_comment_id
      result += '#comment_' + Comment.encode_open_id(self.new_comment_id)
    end
    result
  end

  def toggle_deleted
    if self.state == 0
      self.unread = false if self.unread
      self.state = 1
    else
      self.state = 0
    end
    self.save
  end
end
