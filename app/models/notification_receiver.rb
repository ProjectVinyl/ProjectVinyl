class NotificationReceiver < ApplicationRecord
  belongs_to :user
  
  def self.push_notifications(users, message)
    begin
      PushNotificationJob.perform_later(users, message)
    rescue Exception => e
      puts e
    end
  end
  
  def create_packet(message)
    {
      push: message,
      counters: {
        notices: user.notification_count,
        feeds: user.feed_count,
        mail: user.message_count
      }
    }
  end
  
  def create_payload(message)
    {
      message: create_packet(message).to_json,
      endpoint: self.endpoint,
      p256dh: self.pauth,
      auth: self.auth,
      ttl: 24 * 60 * 60,
      vapid: {
        subject: 'https://www.projectvinyl.net',
        public_key: Rails.application.secrets.vapid_public_key,
        private_key: Rails.application.secrets.vapid_private_key
      }
    }
  end
end
