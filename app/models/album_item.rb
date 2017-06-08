class AlbumItem < ActiveRecord::Base
  belongs_to :album
  belongs_to :video
  has_one :direct_user, through: :video

  def tiny_thumb(user)
    self.video.tiny_thumb(user)
  end

  def user
    self.direct_user || @dummy || (@dummy = User.dummy(self.video.user_id))
  end

  def removeSelf
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
      if self.album.ordering && self.album.ordering > 0
        self.album.ordering = 0
        self.album.save
      end
      self.index = newIndex
      self.save
    end
  end

  def link
    self.video.link + "?" + self.ref
  end

  def ref
    'list=' + self.album_id.to_s + '&index=' + self.index.to_s
  end

  def virtual?
    self.album.virtual?
  end
end
