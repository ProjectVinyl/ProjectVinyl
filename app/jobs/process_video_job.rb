class ProcessVideoJob < ApplicationJob
  queue_as :default

  def perform(video_id)
    video = Video.find(video_id)
    video.set_status(false)

    encode_file(video_id, video.webm_path, 'webm') do |a|
      encode_file(video_id, a.mpeg_path, 'mp4') do |b|
        encode_file(video_id, b.audio_path, 'mp3') do |c|
          c.set_status(true)
          c.update_file_locations
        end
      end
    end
  end

  def encode_file(video_id, output, ext)
    video = Video.find(video_id)
    if video.file == '.' + ext
      return yield(video)
    end

    Ffmpeg.encode_file(video, video.video_path, output, ext) do
      yield(Video.find(video_id)) if block_given?
    end
  end
end
