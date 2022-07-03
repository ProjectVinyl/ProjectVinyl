require 'projectvinyl/web/ajax'

module Import
  #
  # Retrieves the thumbnail from either TPA or youtube
  #
  class VideoThumbnailJob < ApplicationJob
    queue_as :default

    def perform(video_id, archived, yt_id)
      video = Video.find(video_id)

      if !archived.key?(:error) && archived[:file_paths][:thumbnail].exist?
        FileUtils.mkdir_p File.dirname(video.cover_path)

        ThumbnailExtractor.extract_from_image(
          archived[:file_paths][:thumbnail],
          video.cover_path,
          video.tiny_cover_path
        )
      else
        ProjectVinyl::Web::Ajax.get("https://i.ytimg.com/vi/#{yt_id}/maxresdefault.jpg") do |body|
          temp = video.cover_path.to_s + '.jpg'
          video.store_file(temp, body)

          ThumbnailExtractor.extract_from_image(
            temp,
            video.cover_path,
            video.tiny_cover_path
          ) do
            File.delete temp
          end
        end
      end

      video.save
    end
  end
end
