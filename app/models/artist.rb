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
  
  def setGenres(genres)
    if genres
      Genre.loadGenres(genres, self)
    end
  end
  
  def setAvatar(avatar)
    if !avatar || avatar.content_type.include?('image/')
      if img('avatar', avatar)
        self.mime = avatar.content_type
      else
        self.mime = nil
      end
    end
  end
  
  def setBanner(banner)
    if !banner || banner.content_type.include?('image/')
      self.banner_set = img('banner', banner)
    end
  end
  
  private
  def img(type, uploaded_io)
    path = Rails.root.join('public', type, self.id.to_s)
    if File.exists?(path)
      File.delete(path)
    end
    if uploaded_io
      File.open(path, 'wb') do |file|
        file.write(uploaded_io.read)
        return true
      end
    end
    return false
  end
end