class MoreForumsStuff < ActiveRecord::Migration
  def change
    add_column :comment_threads, :total_comments, :integer, default: 0
    CommentThread.reset_column_information
    CommentThread.all.each do |t|
      t.total_comments = Comment.where(comment_thread_id: t.id, hidden: false).count
      t.save
    end
  end
end
