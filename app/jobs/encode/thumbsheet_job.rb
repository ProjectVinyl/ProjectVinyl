
module Encode
  class ThumbsheetJob < ApplicationJob
    queue_as :default

    def perform(video_id)
      video = Video.find(video_id)
      video.del_file(video.frames_path)
      FileEncoder.extract_tile_sheet(video, video.video_path, video.frames_path) do
        Video.find(video_id).update_file_locations
      end
    end
  end
end
