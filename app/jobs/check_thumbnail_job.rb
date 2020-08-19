class CheckThumbnailJob < ApplicationJob
  queue_as :default

  def self.queue_videos(videos, queue = :default)
    begin
      videos.pluck(:id).find_each(batch_size: 500){|id| CheckThumbnailJob.set(queue: queue).perform_later(id) }
    rescue Exception => e
      return "Error: Could not schedule action."
    end

    "All thumbnails have been queue for a refresh"
  end

  def perform(video_id)
    video = Video.find(video_id)
    video.uncache

    if !video.audio_only
      if video.has_cover?
        if !video.has_tiny_cover?
          Ffmpeg.extract_tiny_thumb_from_existing(video.cover_path, video.tiny_cover_path)
        end
      elsif video.has_video?
        video.del_file(video.tiny_cover_path)

        time = video.duration.to_f / 2
        Ffmpeg.extract_thumbnail(video.video_path, video.cover_path, video.tiny_cover_path, time)
      end
    end
  end
end
