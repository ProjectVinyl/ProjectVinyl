module Encode
  #
  # Extracts thumbnails from a video or an uploaded cover image
  #
  class ThumbnailJob < ApplicationJob
    queue_as :default

    def self.queue_video(video, cover, time, queue = :default)
      video.uncache
      video.remove_cover_files
      video.thumbnail_time = time
      video.save_file(video.cover_path, cover, 'image/')

      begin
        ThumbnailJob.set(queue: queue).perform_later(video.id)
      rescue Exception => e
        return "Error: Could not schedule action."
      end

      return "Thumbnail Reset." if (cover.nil? && time.nil?)

      "Processing Scheduled"
    end

    def perform(video_id)
      video = Video.find(video_id)

      if video.cover_path.exist?
        video.del_file(video.tiny_cover_path)
        ThumbnailExtractor.extract_from_image(
          video.cover_path, video.cover_path, video.tiny_cover_path
        )
      elsif !video.audio_only
        video.del_file(video.tiny_cover_path)
        ThumbnailExtractor.extract_from_video(
          video.video_path,
          video.cover_path,
          video.tiny_cover_path,
          video.thumbnail_time
        )
      end
    end
  end
end
