class Album < ActiveRecord::Base
  belongs_to :user, foreign_key: "owner_id"
  has_many :album_items
  has_many :videos, :through => :album_items
  
  def setTitle(title)
    self.title = title
    self.safe_title = ApplicationHelper.url_safe(title)
    self.safe
  end
  
  def ownedBy(user)
    return self.owner_id == user.id || (self.hidden == false && user.is_admin)
  end
  
  def transferTo(user)
    self.user = user
    self.save
    self.videos.each do |video|
      video.transferTo(user)
    end
  end
  
  def addItem(video)
    index = self.album_items.length
    self.album_items.create(video_id: video.id, index: index)
    self.album_items.order(:index).each_with_index do |i,index|
      i.index = index
      i.save
    end
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