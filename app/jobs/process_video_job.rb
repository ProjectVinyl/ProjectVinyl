class ProcessVideoJob < ApplicationJob
  queue_as :default

  def perform(video_id)
    video = Video.find(video_id)
    video.set_status(false)
    video.read_media_attributes!

    encode_file(video_id, video.webm_path, 'webm', !video.audio_only) do |a|
      encode_file(video_id, a.mpeg_path, 'mp4', !video.audio_only) do |b|
        encode_file(video_id, b.audio_path, 'mp3', true) do |c|
          c.set_status(true)
          c.update_file_locations
        end
      end
    end
  end

  def encode_file(video_id, output, ext, must_do)
    video = Video.find(video_id)
    if !must_do || video.file == '.' + ext
      return yield(video)
    end

    Ffmpeg.encode_file(video, video.video_path, output, ext) do
      yield(Video.find(video_id)) if block_given?
    end
  end
end
