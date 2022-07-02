
module Encode
  class AudioFilesJob < ApplicationJob
    queue_as :default

    def perform(video_id)
      video = Video.find(video_id)
      FileEncoder.encode_file(video, video.video_path, video.audio_path, 'mp3') do
        Video.find(video_id).update_file_locations
      end
    end
  end
end
