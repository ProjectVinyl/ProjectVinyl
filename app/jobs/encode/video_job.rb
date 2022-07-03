module Encode
  #
  # Encodes both a video's AV files and tilesheets
  #
  class VideoJob < ApplicationJob
    queue_as :default

    def self.queue_video(video, queue = :default)
      video.set_status(nil)

      begin
        Encode::VideoJob.set(queue: :default).perform_later(video.id)
      rescue Exception => e
        return "Error: Could not schedule action."
      end

      "Processing Scheduled"
    end

    def perform(video_id)
      video = Video.find(video_id)
      video.del_file(video.frames_path)
      MultiFileEncoder.encode_multi(video, video.video_path, [
        video.audio_path,
        video.webm_path,
        video.mpeg_path
      ], tile_sheet_path: video.audio_only ? nil : video.frames_path) do
        video = Video.find(video_id)
        video.set_status(true)
        video.update_file_locations
      end
    end
  end
end
