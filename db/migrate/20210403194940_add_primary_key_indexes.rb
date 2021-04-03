class AddPrimaryKeyIndexes < ActiveRecord::Migration[5.1]
  def change
    add_index :api_tokens, :user_id
    add_index :comment_replies, :parent_id
    add_index :comment_replies, :comment_id
    add_index :comment_votes, :comment_id
    add_index :comments, :comment_thread_id
    add_index :notification_receivers, :user_id
    add_index :notifications, :user_id
    add_index :pms, :user_id
    add_index :pms, :sender_id
    add_index :pms, :receiver_id
    add_index :pms, :state
    add_index :pms, :unread
    add_index :reports, [:reportable_id, :reportable_type]
    add_index :reports, :user_id
    add_index :site_filters, :user_id
    add_index :site_notices, :active
    add_index :tag_histories, :video_id
    add_index :tag_histories, :tag_id
    add_index :tag_histories, :user_id
    add_index :tag_implications, :tag_id
    add_index :tag_implications, :implied_id
    add_index :tag_subscriptions, :user_id
    add_index :tag_subscriptions, :tag_id
    add_index :thread_subscriptions, :user_id
    add_index :thread_subscriptions, :comment_thread_id
    add_index :user_badges, :badge_id
    add_index :user_badges, :user_id
    add_index :video_chapters, :video_id
    add_index :video_genres, :tag_id
    add_index :votes, :user_id
    add_index :votes, :video_id
    add_index :watch_histories, :user_id
    add_index :watch_histories, :video_id
  end
end
