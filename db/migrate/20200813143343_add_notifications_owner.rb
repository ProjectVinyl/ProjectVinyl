class AddNotificationsOwner < ActiveRecord::Migration[5.1]
  def change
    add_column :notifications, :owner_id, :integer
    add_column :notifications, :owner_type, :text

    Notification.reset_column_information
    Notification.all.update_all("owner_type = REGEXP_REPLACE(sender, '_[0-9]+', '')")
    Notification.all.update_all("owner_id = REGEXP_REPLACE(REPLACE(sender, '_', ''), '[^0-9]+', '')::integer")
    Notification.where("sender LIKE 'comments_%'").update_all("owner_type = 'Comment'")
    Notification.where("sender LIKE 'comment_threads_%'").update_all("owner_type = 'CommentThread'")
    Notification.where("sender LIKE 'reports_%'").update_all("owner_type = 'Report'")
  end
end
