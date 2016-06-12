class Album < ActiveRecord::Base
  belongs_to :owner, polymorphic: true
  has_many :album_items
  has_many :videos, :through => :album_items
  
  def ownedBy(user)
    if self.owner_type == 'User'
      return self.owner_id == user.id
    elsif self.owner_type == 'Artist'
      return user.is_admin || (user.artist_id && self.owner_id == user.artist_id)
    end
  end
  
  def transferTo(artist)
    self.artist = artist
    self.save
    self.videos.each do |video|
      video.transferTo(artist)
    end
  end
  
  def addItem(video)
    index = self.album_items.length
    self.album_items.create(video_id: video.id, index: index)
  end
  
  def toggle(video)
    if item = self.album_items.where(video_id: video.id).first
      item.removeSelf
      return false
    else
      self.addItem(video)
      return true
    end
  end
end