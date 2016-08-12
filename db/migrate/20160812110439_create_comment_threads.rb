class CreateCommentThreads < ActiveRecord::Migration
  def change
    create_table :comment_threads do |t|
      t.string :title, default: ""
      t.integer :user_id
      t.references :owner, polymorphic: true, index: true
      t.timestamps null: false
    end
    rename_column :comments, :video_id, :comment_thread_id
    add_column :videos, :comment_thread_id, :integer
    Video.reset_column_information
    Video.update_all('comment_thread_id = id')
    items = Video.all.map do |v|
      { id: v.id, user_id: v.user_id, title: v.title, created_at: v.created_at, owner_id: v.id, owner_type: 'Video' }
    end
    CommentThread.create(items)
  end
end
