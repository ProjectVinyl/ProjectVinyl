class EncodeFilesJob < ApplicationJob
  queue_as :default

  def self.queue_video(video, queue = :default)
    video.set_status(nil)

    begin
      EncodeFilesJob.set(queue: queue).perform_later(video.id)
    rescue Exception => e
      return "Error: Could not schedule action."
    end

    "Processing Scheduled"
  end

  def perform(video_id)
    video = Video.find(video_id)
    video.set_status(false)
    video.read_media_attributes!

    encode_file(video_id, video.webm_path, 'webm', !video.audio_only) do |a|
      encode_file(video_id, a.mpeg_path, 'mp4', !a.audio_only) do |b|
        produce_thumb_sheet(video_id, !b.audio_only) do |c|
          encode_file(video_id, c.audio_path, 'mp3', true) do |d|
            d.set_status(true)
            d.update_file_locations
          end
        end
      end
    end
  end

  def encode_file(video_id, output, ext, must_do)
    video = Video.find(video_id)
    if !must_do || video.file == '.' + ext
      return yield(video)
    end

    FileEncoder.encode_file(video, video.video_path, output, ext) do
      yield(Video.find(video_id)) if block_given?
    end
  end

  def produce_thumb_sheet(video_id, must_do)
    video = Video.find(video_id)
    if !must_do
      return if !block_given?
      return yield(video)
    end

    video.del_file(video.frames_path)
    FileEncoder.extract_tile_sheet(video, video.video_path, video.frames_path) do
      yield(Video.find(video_id)) if block_given?
    end
  end
end
