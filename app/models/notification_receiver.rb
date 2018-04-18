class NotificationReceiver < ApplicationRecord
	belongs_to :user
	
	def self.push_notifications(users)
		NotificationReceiver.includes(:user).where('user_id IN (?)', users).each do |r|
			begin
				Webpush.payload_send(r.create_payload(yield(r.user)))
			rescue Exception => e
				r.destroy
				puts e
			end
		end
	end
	
	def create_payload(packet)
		{
			message: packet.to_json,
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
