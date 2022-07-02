require 'projectvinyl/web/ajax'

module Import
  class VideoThumbnailJob < ApplicationJob
    queue_as :default

    def self.perform_now(video, archived, yt_id)
      if !archived.key?(:error) && archived[:file_paths][:thumbnail].exist?
        FileUtils.mkdir_p File.dirname(video.cover_path)
        Ffmpeg.run_command('-i', archived[:file_paths][:thumbnail], video.cover_path) do
          Ffmpeg.extract_tiny_thumb_from_existing(video.cover_path, video.tiny_cover_path)
        end
      else
        ProjectVinyl::Web::Ajax.get("https://i.ytimg.com/vi/#{yt_id}/maxresdefault.jpg") do |body|
          temp = video.cover_path.to_s + '.jpg'
          video.store_file(temp, body)
          Ffmpeg.run_command('-i', temp, video.cover_path) do
            Ffmpeg.extract_tiny_thumb_from_existing(video.cover_path, video.tiny_cover_path)
            File.delete(temp)
          end
        end
      end

      video.save
    end

    def perform(video_id, archived, yt_id)
      VideoThumbnailJob.perform_now(Video.find(video_id), archived, yt_id)
    end
  end
end
