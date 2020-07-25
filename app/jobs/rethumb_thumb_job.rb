class RethumbThumbJob < ApplicationJob
  queue_as :default

  def perform(video_id)
    video = Video.find(video_id)

    video.uncache

    if !video.audio_only
      if video.has_file(video.cover_path)
        if !video.has_file(video.tiny_cover_path)
          Ffmpeg.extract_tiny_thumb_from_existing(video.cover_path, video.tiny_cover_path)
        end
      elsif video.has_file(video.video_path)
        video.del_file(video.tiny_cover_path)

        time = video.duration.to_f / 2
        Ffmpeg.extract_thumbnail(video.video_path, video.cover_path, video.tiny_cover_path, time)
      end
    end
  end
end
