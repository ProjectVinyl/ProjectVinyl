class FeedNotifications < ActiveRecord::Migration
  def change
    add_column :users, :feed_count, :integer, default: 0
    User.reset_column_information
    User.update_all('feed_count = 0')
  end
end
