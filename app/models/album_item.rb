class AlbumItem < ApplicationRecord
  belongs_to :album
  belongs_to :video
  has_one :direct_user, through: :video
  
  scope :discriminate, ->(comparitor, current, user) {
    where('album_items.index ' + comparitor + ' ?', current).reject do |i|
      (i.video.is_hidden_by(user) || i.video.hidden)
    end
  }
  
  before_destroy :shift_indices
  
  def tiny_thumb(user)
    self.video.tiny_thumb(user)
  end
  
  def owned_by(user)
    self.album.owned_by(user)
  end
  
  def user
    self.direct_user || @dummy || (@dummy = User.dummy(self.video.user_id))
  end
  
  def move(new_index)
    from = self.index
    to = new_index
    if to != from
      if to < from
        self.update_indices(self.album.album_items.where('album_items.index >= ? AND album_items.index < ?', to, from), '+')
      else
        self.update_indices(self.album.album_items.where('album_items.index > ? AND album_items.index <= ?', from, to), '-')
      end
      if self.album.ordering && self.album.ordering > 0
        self.album.ordering = 0
        self.album.save
      end
      self.index = new_index
      self.save
    end
  end

  def link
    "#{self.video.link}?#{self.ref}"
  end

  def ref
    "list=#{self.album_id}&index=#{self.index}"
  end

  def virtual?
    self.album.virtual?
  end
  
  protected
  def shift_indices
    self.update_indices(self.album.album_items.where('album_items.index > ?', self.index), '-')
  end
  
  def update_indices(items, op)
    items.update_all("album_items.index = album_items.index #{op} 1")
  end
end
