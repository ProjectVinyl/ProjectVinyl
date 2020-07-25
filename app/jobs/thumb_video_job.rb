class ThumbVideoJob < ApplicationJob
  queue_as :default

  def perform(video_id, cover, time)
    video = Video.find(video_id)

    video.uncache
    video.remove_cover_files

    if video.save_file(video.cover_path, cover, 'image/')
      Ffmpeg.extract_tiny_thumb_from_existing(video.cover_path, video.tiny_cover_path)
    elsif !video.audio_only
      time = time ? time.to_f : video.duration.to_f / 2
      Ffmpeg.extract_thumbnail(video.video_path, video.cover_path, video.tiny_cover_path, time)
    end
  end
end
