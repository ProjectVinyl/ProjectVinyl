class AlbumItem < ApplicationRecord
  include Reorderable

  belongs_to :album
  belongs_to :video
  has_one :direct_user, through: :video

  has_siblings :album_items
  after_move :update_album_ordering

  def tiny_thumb(user, filter)
    self.video.tiny_thumb(user, filter)
  end

  def owned_by(user)
    self.album.owned_by(user)
  end

  def user
    self.direct_user || @dummy || (@dummy = User.dummy(self.video.user_id))
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

  private
  def album_items
    album.album_items
  end
  def update_album_ordering
    if self.album.ordering && self.album.ordering > 0
      self.album.ordering = 0
      self.album.save
    end
  end
end
