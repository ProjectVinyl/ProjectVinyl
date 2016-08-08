class Cleanup < ActiveRecord::Migration
  def change
    remove_column :artist_genres, :genre_id
    remove_column :video_genres, :genre_id
    add_index :artists, :name, unique: true
  end
end
