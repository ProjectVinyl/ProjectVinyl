class RemoveUnneededIds < ActiveRecord::Migration
  def change
    remove_column :artist_genres, :id
    remove_column :video_genres, :id
  end
end
