class Aliases < ActiveRecord::Migration
  def change
    add_column :artist_genres, :o_tag_id, :integer
    add_column :video_genres, :o_tag_id, :integer
    ArtistGenre.update_all('o_tag_id = tag_id')
    VideoGenre.update_all('o_tag_id = tag_id')
  end
end
