class Album < ApplicationRecord
  include Albums::AlbumLike
  include Unlistable, Titled, Statable
  include Albums::Orderable

  belongs_to :user
  has_many :album_items
  has_many :videos, through: :album_items
  has_many :users, foreign_key: :star_id

  def video_set
    @video_set ||= Albums::VideoSet.new(self)
  end

  def transfer_to(user)
    self.user = user
    save
    videos.each do |video|
      video.transfer_to(user)
    end
  end

  def link
    "/albums/#{id}-#{safe_title}"
  end
end
