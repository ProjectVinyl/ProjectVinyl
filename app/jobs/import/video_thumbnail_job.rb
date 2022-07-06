require 'projectvinyl/web/youtube'
require 'projectvinyl/web/the_pony_archive'

module Import
  #
  # Retrieves the thumbnail from either TPA or youtube
  #
  class VideoThumbnailJob < ApplicationJob
    queue_as :default

    def perform(video_id, archived, yt_id)
      archived = ProjectVinyl::Web::ThePonyArchive.video_meta(yt_id) if archived.nil?
      video = Video.find(video_id)
      video.del_file video.cover_path
      video.del_file video.tiny_cover_path

      if !archived.key?(:error) && archived[:file_paths][:thumbnail].exist?
        FileUtils.mkdir_p File.dirname(video.cover_path)
        ThumbnailExtractor.extract_from_image(
          archived[:file_paths][:thumbnail],
          video.cover_path,
          video.tiny_cover_path
        )
      else
        ProjectVinyl::Web::Youtube.download_thumbnail(yt_id) do |body|
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
