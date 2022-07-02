
module Encode
  class VideoFilesJob < ApplicationJob
    queue_as :default

    def perform(video_id)
      video = Video.find(video_id)
      video.set_status(false)
      video.read_media_attributes
      video.save

      FileEncoder.encode_file(video, video.video_path, video.webm_path, 'webm') do
        video = Video.find(video_id)
        FileEncoder.encode_file(video, video.video_path, video.mpeg_path, 'mp4') do
          video = Video.find(video_id)
          video.set_status(true)
          video.update_file_locations
        end
      end
    end
  end
end
