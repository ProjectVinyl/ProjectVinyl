class Star < ActiveRecord::Base
  belongs_to :user
  belongs_to :video
  
  def removeSelf()
    oldIndex = self.index
    self.destroy
    self.user.stars.where('`stars`.`index` > ?', oldIndex).each do |i|
      i.index = i.index - 1
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
    changed = self.user.stars.where(index: dirtyStart..dirtyEnd)
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
  end
end
