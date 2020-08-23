class AlbumItem < ApplicationRecord
  belongs_to :album
  belongs_to :video
  has_one :direct_user, through: :video

  scope :following, ->(current) { discriminate('>', current) }
  scope :leading, ->(current) { discriminate('<', current) }
  scope :discriminate, ->(comparitor, current) { where('album_items.index ' + comparitor + ' ?', current) }
  
  before_destroy :shift_indices
  
  def tiny_thumb(user, filter)
    self.video.tiny_thumb(user, filter)
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

  def tooltip
    video.hidden ? "hidden" : "#{video.title} - #{video.user.username}"
  end

  def title
    video.hidden ? "hidden" : video.title
  end

  protected
  def shift_indices
    self.update_indices(self.album.album_items.where('album_items.index > ?', self.index), '-')
  end
  
  def update_indices(items, op)
    items.update_all("index = index #{op} 1")
  end
end
