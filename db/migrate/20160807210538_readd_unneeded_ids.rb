class ReaddUnneededIds < ActiveRecord::Migration
  def change
    add_column :artist_genres, :id, :primary_key
    add_column :video_genres, :id, :primary_key
  end
end
