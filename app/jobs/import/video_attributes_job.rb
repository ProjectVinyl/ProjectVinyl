module Import
  class VideoAttributesJob < ApplicationJob
    queue_as :default

    def perform(video_id, archived, yt_id)
      video = Video.find(video_id)
      data = VideoJob.data_for(yt_id)

      attributes = data[:attributes]
      included = data[:included] || {}

      video.title = attributes[:title]
      video.description = attributes[:description][:bbc]

      if !video.video_path.exist?
        video.width = attributes[:dimensions][:width]
        video.height = attributes[:dimensions][:height]

        if !archived.key?(:error) && archived[:file_paths][:additional_sources].length > 0
          if archived[:file_paths][:video].exist?
            video.file = archived[:file_paths][:video].extname
          else
            video.file = archived[:file_paths][:additional_sources][0].extname
          end
        else
          video.file = '.' + attributes[:extension]
        end
        video.mime = Mimes.mime(video.file)
      end
      video.save

      tags = (included[:tags] || []).uniq
      
      if included[:uploader]
        artist_tag = Tag.sanitize_name(included[:uploader][:name])
        tags << 'artist:' + artist_tag if artist_tag.present?
      end

      if (changes = video.set_all_tags(Tag.create_from_names(tags)))
        TagHistory.record_tag_changes(changes[0], changes[1], video.id, video.user_id)
      end
    end
  end
end
