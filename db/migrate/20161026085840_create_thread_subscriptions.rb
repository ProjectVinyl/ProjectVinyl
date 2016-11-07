class CreateThreadSubscriptions < ActiveRecord::Migration
  def change
    create_table :thread_subscriptions do |t|
      t.integer :user_id
      t.integer :comment_thread_id
      t.timestamps null: false
    end
    CommentThread.all.each do |th|
      subscribers = th.comments.pluck(:user_id)
      if th.user_id
        subscribers << th.user_id
      end
      User.where('id IN (?)', subscribers.uniq).each do |u|
        th.subscribe(u)
      end
    end
  end
end
