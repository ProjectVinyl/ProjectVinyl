class CreateNotificationReceivers < ActiveRecord::Migration[5.1]
  def change
    create_table :notification_receivers do |t|
    	t.integer :user_id
    	t.string :endpoint
    	t.string :auth	#key.auth
    	t.string :pauth #keys.p256dh
    	
  		t.timestamps
    end
  end
end
