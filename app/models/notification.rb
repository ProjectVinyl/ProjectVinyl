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

  def self.send_to_admins(notification_params:, toast_params:)
    send_to(User.where('role > 1').pluck(:id),
      notification_params: notification_params,
      toast_params: toast_params,
      delete: false
    )
  end

  def self.send_to(*receivers, notification_params:, toast_params:, delete: true)
    receivers = receivers.flatten
    Notification.where(owner: notification_params[:originator]).where('user_id IN (?)', receivers).delete_all if delete
    Notification.create(receivers.uniq.map{ |receiver| __create_params(receiver, notification_params) })
    User.where('id IN (?)', receivers).update_all('notification_count = (SELECT COUNT(*) FROM notifications WHERE user_id = users.id AND unread = true)')
    NotificationReceiver.push_notifications(receivers, toast_params)
  end

  private
  def self.__create_params(receiver, message:, location:, originator:)
    {
      user_id: receiver,
      message: message,
      source: location,
      owner: originator,
      unread: true
    }
  end
end
