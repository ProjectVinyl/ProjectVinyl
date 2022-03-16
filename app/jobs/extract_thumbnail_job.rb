class ExtractThumbnailJob < ApplicationJob
  queue_as :default

  def self.queue_video(video, cover, time, queue = :default)
    video.uncache
    video.remove_cover_files
    video.save_file(video.cover_path, cover, 'image/')

    begin
      ExtractThumbnailJob.set(queue: queue).perform_later(video.id, time)
    rescue Exception => e
      return "Error: Could not schedule action."
    end

    return "Thumbnail Reset." if (cover.nil? && time.nil?)

    "Processing Scheduled"
  end

  def perform(video_id, time)
    video = Video.find(video_id)

    video.del_file(video.tiny_cover_path)
    
    if video.has_cover?
      Ffmpeg.extract_tiny_thumb_from_existing(video.cover_path, video.tiny_cover_path)
    elsif !video.audio_only
      time = time ? time.to_f : video.duration.to_f / 2
      Ffmpeg.extract_thumbnail(video.video_path, video.cover_path, video.tiny_cover_path, time)
    end
  end
end
