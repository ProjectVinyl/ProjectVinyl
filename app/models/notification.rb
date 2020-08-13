class Notification < ApplicationRecord
  include Periodic
  include Counterable

  belongs_to :user
  belongs_to :owner, polymorphic: true

  conditional_counter_cache :user, :unread_notifications, :unread, :notification_count

  def subscribeable?
    owner_type == 'CommentThread'
  end

  def sender
    "#{owner_type}_#{owner_id}"
  end

  def self.notify_admins(sender, message, source)
    Notification.notify_receivers(User.where('role > 1').pluck(:id), sender, message, source, false)
  end

  def self.notify_receivers_without_delete(receivers, sender, message, source)
    Notification.notify_receivers(receivers, sender, message, source, false)
  end

  def self.notify_receivers(receivers, sender, message, source, del = true)
    Notification.where(owner: sender).where('user_id IN (?)', receivers).delete_all if del
    Notification.create(receivers.uniq.map{ |receiver| __create_params(receiver, message, source, sender) })

    User.where('id IN (?)', receivers).update_all('notification_count = (SELECT COUNT(*) FROM notifications WHERE user_id = users.id AND unread = true)')

    NotificationReceiver.push_notifications(receivers, {
      title: message,
      params: {
        badge: '/favicon.ico',
        icon: sender.icon,
        body: sender.preview
      }
    })
  end

  private
  def self.__create_params(receiver, message, source, owner)
    {
      user_id: receiver,
      message: message,
      source: source,
      owner: owner,
      unread: true
    }
  end
end
