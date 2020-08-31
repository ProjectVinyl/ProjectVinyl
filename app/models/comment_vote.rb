class CommentVote < ApplicationRecord
  belongs_to :user
  belongs_to :comment, counter_cache: :likes_count
end
