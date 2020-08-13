class VideoGenre < ApplicationRecord
  belongs_to :video
  belongs_to :tag, counter_cache: :video_count
end
