class Notification < ApplicationRecord
  include Periodic
  
  scope :preload_comment_threads, -> {
    mapping = {}
    ids = []
    all.find_each do |i|
      if i.comment_thread_id > 0
        ids << i.comment_thread_id
        mapping[i.comment_thread_id] = [] if !mapping.key?(i.comment_thread_id)
        mapping[i.comment_thread_id] << i
      end
      CommentThread.where('id IN (?)', ids.uniq).find_each do |t|
        mapping[t.id].each do |c|
          c.comment_thread = t
        end
      end
    end
  }

  def comment_thread
    @comment_thread || (comment_thread = CommentThread.where(id: self.comment_thread_id).first)
  end

  attr_writer :comment_thread

  def comment_thread_id
    @comment_thread_id || (@comment_thread_id = self.sender.index('comment_threads_') == 0 ? sender.sub('comment_threads_', '').to_i : 0)
  end

  def comment_thread_id=(i)
    self.sender = "comment_thread_#{i}"
  end
  
  def self.notify_receivers(receivers, sender, message, source, del = true)
    sender = "#{sender.class.table_name}_#{sender.id}"
    if del
      Notification.where('user_id IN (?) AND sender = ?', receivers, sender).delete_all
    end
    Notification.create(receivers.uniq.map do |receiver|
      {
        user_id: receiver,
        message: message,
        source: source,
        sender: sender,
        unread: true
      }
    end)
    User.where('id IN (?)', receivers).update_all('notification_count = (SELECT COUNT(*) FROM `notifications` WHERE user_id = `users`.id AND unread = true)')
  end

  def self.notify_admins(sender, message, source)
    Notification.notify_receivers(User.where('role > 1').pluck(:id), sender, message, source, false)
  end

  def self.notify_receivers_without_delete(receivers, sender, message, source)
    Notification.notify_receivers(receivers, sender, message, source, false)
  end
end
