class Album < ActiveRecord::Base
  belongs_to :artist
  has_many :album_items
  has_many :videos, :through => :album_items
  
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