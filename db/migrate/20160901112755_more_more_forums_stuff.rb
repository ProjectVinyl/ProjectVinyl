class MoreMoreForumsStuff < ActiveRecord::Migration
  def change
    add_column :comment_threads, :safe_title, :string
    CommentThread.reset_column_information
    CommentThread.all.each do |t|
      t.set_title(t.get_title)
    end
  end
end
