class VideoDuplicates < ActiveRecord::Migration
  def change
    add_column :videos, :duplicate_id, :integer, default: 0
    add_column :album_items, :o_video_id, :integer, default: 0
    add_column :comments, :o_comment_thread_id, :integer, default: 0
    Comment.update_all('o_comment_thread_id = comment_thread_id')
    AlbumItem.update_all('o_video_id = video_id')
    
    add_index :tags, :name, :unique => true
  end
end
