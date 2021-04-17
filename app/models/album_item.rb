class AlbumItem < ApplicationRecord
  include Albums::Item
  include Reorderable

  belongs_to :album
  belongs_to :video
  has_one :direct_user, through: :video

  has_siblings :album_items
  after_move :update_album_ordering

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
