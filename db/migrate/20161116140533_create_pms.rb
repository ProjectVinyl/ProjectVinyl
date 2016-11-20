class CreatePms < ActiveRecord::Migration
  def change
    create_table :pms do |t|
      t.integer :state, default: 0
      t.boolean :unread, default: false
      t.integer :sender_id
      t.integer :receiver_id
      t.integer :comment_thread_id
      t.integer :new_comment_id
      t.integer :user_id
    end
  end
end
