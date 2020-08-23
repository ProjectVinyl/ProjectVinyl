class MoreMoreForumsStuff < ActiveRecord::Migration
  def change
    add_column :comment_threads, :safe_title, :string
    CommentThread.reset_column_information
    CommentThread.all.each do |t|
      t.title = t.title
      t.save
    end
  end
end
