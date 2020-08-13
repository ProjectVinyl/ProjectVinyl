class RemoveNotificationSender < ActiveRecord::Migration[5.1]
  def change
    remove_column :notifications, :sender
  end
end
