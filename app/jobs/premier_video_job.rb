class PremierVideoJob < ApplicationJob
  queue_as :default

  def self.enqueu_video(video)
    begin
      if !video.premiered_at.nil? && video.premiered_at > DateTime.now
        PremierVideoJob.set(queue: queue, wait_until: video.premiered_at.in_time_zone).perform_later(video.id)
      end
    rescue Exception => e
      return "Error: Could not schedule action."
    end

    "Premier Scheduled"
  end

  def perform(video_id)
    Video.find(video_id).publish
  end
end
