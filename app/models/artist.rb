class Artist < ActiveRecord::Base
  has_many :videos
  has_many :albums, as: :owner
  has_many :artist_genres
  has_many :genres, :through => :artist_genres
  
  def removeSelf
    self.videos.each do |video|
      video.removeSelf
    end
    self.destroy
  end
  
  def genres_string
    return Genre.tag_string(self.genres)
  end
end