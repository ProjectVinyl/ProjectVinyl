class Notification < ActiveRecord::Base
  def period
    if self.created_at > Time.zone.now.beginning_of_day
      return "Today"
    end
    if self.created_at > Time.zone.now.yesterday.beginning_of_day
      return "Yesterday"
    end
    self.created_at.strftime('%A %d %B')
  end
  
  def self.notify_recievers(recievers, sender, message, source)
    sender = sender.class.table_name + "_" + sender.id.to_s
    batch_data = recievers.uniq.map do |reciever|
      { user_id: reciever,
        message: message,
        source: source,
        sender: sender,
        unread: true
      }
    end
    Notification.where('user_id IN (?) AND sender = ?', recievers, sender).delete_all
    Notification.create(batch_data)
    User.where('id IN (?)', recievers).update_all('notification_count = (SELECT COUNT(*) FROM `notifications` WHERE user_id = `users`.id AND unread = true)')
  end
  
  def self.notify_admins(sender, message, source)
    Notification.notify_recievers_without_delete(User.where('role > 1').pluck(:id), sender, message, source)
  end
  
  def self.notify_recievers_without_delete(recievers, sender, message, source)
    sender = sender.class.table_name + "_" + sender.id.to_s
    batch_data = recievers.uniq.map do |reciever|
      { user_id: reciever,
        message: message,
        source: source,
        sender: sender,
        unread: true
      }
    end
    Notification.create(batch_data)
    User.where('id IN (?)', recievers).update_all('notification_count = (SELECT COUNT(*) FROM `notifications` WHERE user_id = `users`.id AND unread = true)')
  end
end
