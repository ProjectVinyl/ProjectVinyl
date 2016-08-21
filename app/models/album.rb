class Album < ActiveRecord::Base
  belongs_to :user
  has_many :album_items
  has_many :videos, :through => :album_items
  
  def set_description(text)
    test = ApplicationHelper.demotify(text)
    self.description = text
    self.html_description = ApplicationHelper.emotify(text)
    return self
  end
  
  def set_title(title)
    title = ApplicationHelper.check_and_trunk(title, self.title || "Untitled Album")
    self.title = title
    self.safe_title = ApplicationHelper.url_safe(title)
    self.save
  end
  
  def ownedBy(user)
    return self.user_id == user.id || (self.hidden == false && user.is_admin)
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