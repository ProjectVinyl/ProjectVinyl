class PremierVideoJob < ApplicationJob
  queue_as :default

  def perform(video_id)
    video = Video.find(video_id)
    video.set_hidden(false)
  end
end
