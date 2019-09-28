module Likeable
  extend ActiveSupport::Concern

  included do
    scope :with_likes, ->(user) {
      if !user.nil?
        return joins("LEFT JOIN votes ON votes.video_id = videos.id AND votes.user_id = #{user.id}")
          .select('videos.*, votes.user_id AS is_liked_flag, votes.negative AS is_like_negative_flag')
      end
    }
  end

  def is_starred_by(user)
    user && user.album_items.where(video_id: id).count > 0
  end

  def star(user)
    user.stars.toggle(self)
  end

  def is_liked
    (respond_to? :is_liked_flag) && is_liked_flag
  end

  def is_like_negative
    (respond_to? :is_like_negative_flag) && is_like_negative_flag
  end

  def is_upvoted
    is_liked && !is_like_negative
  end

  def is_downvoted
    is_liked && is_like_negative
  end
end
