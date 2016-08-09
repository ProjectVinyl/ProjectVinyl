class CreateNotifications < ActiveRecord::Migration
  def change
    create_table :notifications do |t|
      t.string :message
      t.string :source
      t.integer :user_id
    end
    add_column :users, :notification_count, :integer, default: 0
    User.reset_column_information
    User.update_all(notification_count: 0)
  end
end
