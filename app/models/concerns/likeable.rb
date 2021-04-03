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

  def faved?(user)
    user && user.album_items.where(video_id: id).count > 0
  end

  def star(user)
    user.stars.toggle(self)
    self.favourites = self.favouriters.count
    save
    self.favourites
  end

  def liked?
    (respond_to? :is_liked_flag) && is_liked_flag
  end

  def disliked?
    (respond_to? :is_like_negative_flag) && is_like_negative_flag
  end

  def upvoted?
    liked? && !disliked?
  end

  def downvoted?
    liked? && disliked?
  end
end
