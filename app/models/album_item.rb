class AlbumItem < ActiveRecord::Base
  belongs_to :album
  belongs_to :video
  has_one :direct_user, :through => :video
  
  def user
    return self.direct_user || @dummy || (@dummy = User.dummy(self.video.user_id))
  end
  
  def removeSelf()
    old_index = self.index
    self.destroy
    self.album.album_items.where('`album_items`.index > ?', old_index).update_all('`album_items`.index = `album_items`.index - 1')
  end
  
  def move(newIndex)
    from = self.index
    to = newIndex
    if to != from
      if to < from
        self.album.album_items.where('`album_items`.index >= ? AND `album_items`.index < ?', to, from).update_all('`album_items`.index = `album_items`.index + 1')
      else
        self.album.album_items.where('`album_items`.index > ? AND `album_items`.index <= ?', from, to).update_all('`album_items`.index = `album_items`.index - 1')
      end
      self.index = newIndex
      self.save
    end
  end
  
  def ref
    return 'list=' + self.album_id.to_s + '&index=' + self.index.to_s
  end
  
  def virtual?
    self.album.virtual?
  end
end