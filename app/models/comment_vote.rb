class CommentVote < ApplicationRecord
  belongs_to :user
  belongs_to :comment, counter_cache: true
end
