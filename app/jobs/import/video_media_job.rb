require 'projectvinyl/web/ajax'

module Import
  #
  # Links supported video formats, downloading if required
  #
  class VideoMediaJob < ApplicationJob
    queue_as :default

    def perform(video_id, archived, yt_id)
      video = Video.find(video_id)

      if !archived.key?(:error) && archived[:file_paths][:additional_sources].length > 0
        FileUtils.mkdir_p File.dirname(video.video_path)
        archived[:file_paths][:additional_sources].each do |path|
          ext = path.extname
          to_path = video.video_path.sub(video.file, ext)
          if to_path != video.video_path
            to_path = video.audio_path if ext == '.mp3'
            to_path = video.webm_path if ext == '.webm'
            to_path = video.mpeg_path if ext == '.mp4'
          end
          FileUtils.ln_s path, to_path, force: true
        end
      else
        Youtubedl.download_video("https://www.youtube.com/watch?v=#{yt_id}", video.video_path.to_s)
      end

      video.realise_checksum
      video.read_media_attributes
      video.save
      Encode::VideoJob.perform_later(video.id)
    end
  end
end
