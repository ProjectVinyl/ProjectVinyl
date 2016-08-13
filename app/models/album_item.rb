class AlbumItem < ActiveRecord::Base
  belongs_to :album
  belongs_to :video
  has_one :direct_user, :through => :video
  
  def user
    return self.direct_user || @dummy || (@dummy = User.dummy(self.user_id))
  end
  
  def removeSelf()
    self.destroy
    self.album.album_items.order(:index).each_with_index do |i,index|
      i.index = index
      i.save
    end
  end
  
  def move(newIndex)
    dirtyStart = newIndex
    dirtyEnd = self.index
    if self.index < dirtyStart
      dirtyStart = dirtyEnd
      dirtyEnd = newIndex
    end
    changed = self.album.album_items.where(index: dirtyStart..dirtyEnd)
    if self.index == dirtyEnd
      changed.each do |i|
        i.index = i.index + 1
        i.save
      end
    else
      changed.each do |i|
        i.index = i.index - 1
        i.save
      end
    end
    self.index = newIndex
    self.save
    self.album.album_items.order(:index).each_with_index do |i,index|
      i.index = index
      i.save
    end
  end
end