class RethumbThumbJob < ApplicationJob
  queue_as :default

  def perform(video_id)
    video = Video.find(video_id)
    video.recreate_thumbs
  end
end
