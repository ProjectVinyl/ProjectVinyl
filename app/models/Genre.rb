class Genre < ActiveRecord::Base
  has_many :video_genres
  has_many :videos, :through => :video_genres
  has_many :artist_genres
  has_many :artists, :through => :artist_genres
end