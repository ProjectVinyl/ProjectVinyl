class Notification < ActiveRecord::Base
  def self.notify_recievers(recievers, sender, message, source)
    sender = sender.class.table_name + "_" + sender.id.to_s
    batch_data = recievers.uniq.map do |reciever|
      { user_id: reciever,
        message: message,
        source: source,
        sender: sender }
    end
    Notification.where('user_id IN (?) AND sender = ?', recievers, sender).delete_all
    Notification.create(batch_data)
    User.where('id IN (?)', recievers).update_all('notification_count = notification_count + 1')
  end
end
