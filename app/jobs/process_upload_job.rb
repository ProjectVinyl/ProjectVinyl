class ProcessUploadJob < ApplicationJob
  queue_as :default

  def self.queue_video(video, cover, time, queue = :default)
    video.set_status(nil)

    begin
      ProcessUploadJob.set(queue: queue).perform_later(video.id, cover, time)

      if !video.premiered_at.nil?
        PremierVideoJob.set(queue: queue, wait_until: video.premiered_at.in_time_zone).perform_later(video.id)
      end
    rescue Exception => e
      return "Error: Could not schedule action."
    end

    "Processing Scheduled"
  end

  def perform(video_id, cover, time)
    ExtractThumbnailJob.new.perform(video_id, cover, time)
    EncodeFilesJob.new.perform(video_id)
  end
end
