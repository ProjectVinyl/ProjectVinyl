class PushNotificationJob < ApplicationJob
  queue_as :high_priority

  def perform(users, message)
    NotificationReceiver.includes(:user).where('user_id IN (?)', users).find_each(batch_size: 500) do |r|
      begin
        Webpush.payload_send(r.create_payload(message))
      rescue Exception => e
        r.destroy
      end
    end
  end
end
