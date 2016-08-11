class BetterNotifications < ActiveRecord::Migration
  def change
    add_column :notifications, :sender, :string
    change_table(:notifications) { |t| t.timestamps }
    add_column :notifications, :unread, :boolean, default: true
  end
end
