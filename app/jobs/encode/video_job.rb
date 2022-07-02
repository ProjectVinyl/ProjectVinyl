module Encode
  class VideoJob < ApplicationJob
    queue_as :default

    def self.queue_video(video, queue = :default)
      video.set_status(nil)

      begin
        Encode::VideoFilesJob.set(queue: queue).perform_later(video.id)
        Encode::AudioFilesJob.set(queue: :default).perform_later(video.id)
        Encode::ThumbsheetJob.set(queue: :default).perform_later(video.id)
      rescue Exception => e
        return "Error: Could not schedule action."
      end

      "Processing Scheduled"
    end

    def perform(video_id)
      Encode::AudioFilesJob.perform_later(video_id)
      Encode::ThumbsheetJob.perform_later(video_id)
      Encode::VideoFilesJob.perform_now(video_id)
    end
  end
end
