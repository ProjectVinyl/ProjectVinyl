
class ImportYtVideoJob < ApplicationJob
  queue_as :default

  def self.queue_video(user, yt_id, queue = :default)
    Import::VideoJob.create_video(user, yt_id) do |video, data, archived|
        Import::VideoAttributesJob.perform_now(video, data, archived, yt_id)
        Import::VideoThumbnailJob.perform_now(video, archived, yt_id)
        Import::VideoMediaJob.set(queue: queue).perform_later(video.id, archived, yt_id)

        video.listing = 0
        video.publish
        video.save
    end
  end
end
