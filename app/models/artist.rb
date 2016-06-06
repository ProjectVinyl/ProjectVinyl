class Artist < ActiveRecord::Base
  has_many :videos
  has_many :albums
  has_many :artist_genres
  has_many :genres, :through => :artist_genres
  
  def genres_string
    return Genre.tag_string(self.genres)
  end
end