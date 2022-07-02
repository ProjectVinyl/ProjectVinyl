module Import
  class VideoAttributesJob < ApplicationJob
    queue_as :default

    def self.perform_now(video, data, archived, yt_id)
      attributes = data[:attributes]

      video.title = attributes[:title]
      video.description = attributes[:description][:bbc]
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
      video.save

      tags = ((attributes[:included] || {})[:tags] || []).uniq

      if (changes = video.set_all_tags(Tag.create_from_names(tags)))
        TagHistory.record_tag_changes(changes[0], changes[1], video.id, video.user_id)
      end
    end

    def perform(video_id, data, archived, yt_id)
      perform_now(Video.find(video_id), YAML.load(data), YAML.load(archived), yt_id)
    end
  end
end
