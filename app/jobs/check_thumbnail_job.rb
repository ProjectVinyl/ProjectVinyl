class CheckThumbnailJob < ApplicationJob
  queue_as :default

  def self.queue_videos(videos, queue = :default)
    begin
      videos.pluck(:id).find_each(batch_size: 500){|id| CheckThumbnailJob.set(queue: queue).perform_later(id) }
    rescue Exception => e
      return "Error: Could not schedule action."
    end

    "All thumbnails have been queued for a refresh"
  end

  def perform(video_id)
    video = Video.find(video_id)
    video.uncache

    return if video.audio_only

    if video.cover_path.exist?
      ThumbnailExtractor.extract_from_image(
        video.cover_path, video.cover_path, video.tiny_cover_path
      )
    elsif video.has_video?
      video.del_file(video.cover_path)
      video.del_file(video.tiny_cover_path)
      ThumbnailExtractor.extract_from_video(
        video.video_path,
        video.cover_path,
        video.tiny_cover_path,
        video.duration.to_f / 2
      )
    end
  end
end
