class Notification < ApplicationRecord
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
    self.sender = 'comment_thread_' + i.to_s
  end

  def period
    return "Today" if self.created_at > Time.zone.now.beginning_of_day
    if self.created_at > Time.zone.now.yesterday.beginning_of_day
      return "Yesterday"
    end
    self.created_at.strftime('%A %d %B')
  end

  def self.notify_recievers(recievers, sender, message, source, del = true)
    sender = sender.class.table_name + "_" + sender.id.to_s
    if del
      Notification.where('user_id IN (?) AND sender = ?', recievers, sender).delete_all
    end
    batch_data = recievers.uniq.map do |reciever|
      { user_id: reciever,
        message: message,
        source: source,
        sender: sender,
        unread: true }
    end
    Notification.create(batch_data)
    User.where('id IN (?)', recievers).update_all('notification_count = (SELECT COUNT(*) FROM `notifications` WHERE user_id = `users`.id AND unread = true)')
  end

  def self.notify_admins(sender, message, source)
    Notification.notify_recievers(User.where('role > 1').pluck(:id), sender, message, source, false)
  end

  def self.notify_recievers_without_delete(recievers, sender, message, source)
    Notification.notify_recievers(recievers, sender, message, source, false)
  end
end
