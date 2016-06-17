class Artist < ActiveRecord::Base
  has_many :videos
  has_many :albums, as: :owner
  has_many :artist_genres
  has_many :genres, :through => :artist_genres
  
  def self.by_name_or_id(id)
    if artist = Artist.where(id: id).first
      return artist
    end
    return Artist.where(name: id).first
  end
  
  def preload_genres
    self.artist_genres.delete_all
    return self.artist_genres
  end
  
  def removeSelf
    self.videos.each do |video|
      video.removeSelf
    end
    self.destroy
  end
  
  def genres_string
    return Genre.tag_string(self.genres)
  end
  
  def taglist
    if !(user = User.where(artist_id: self.id).first)
      return "Unclaimed Artist"
    end
    if user.is_admin
      return "Admin"
    end
    return "Artist"
  end
end