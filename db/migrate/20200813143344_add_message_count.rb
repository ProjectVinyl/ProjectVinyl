class AddMessageCount < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :message_count, :integer

    User.reset_column_information
    User.all.update_all("message_count = (SELECT COUNT(*) FROM pms WHERE state = 0 AND unread = true)")

    # remove_column :notifications, :sender
  end
end
