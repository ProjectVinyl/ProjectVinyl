class ForumsStuff < ActiveRecord::Migration
  def change
    add_column :comment_threads, :locked, :boolean, default: false
    add_column :comment_threads, :pinned, :boolean, default: false
    CommentThread.reset_column_information
    CommentThread.update_all(locked: false, pinned: false)
  end
end
