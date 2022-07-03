require 'projectvinyl/web/youtube'

module Import
  class SelectiveVideoAttributesJob < ApplicationJob
    queue_as :default

    def perform(video_id, yt_id, fields)
      url = "https://www.youtube.com/watch?v=#{yt_id}"
      video = Video.find(video_id)
      
      data = ProjectVinyl::Web::Youtube.get(url, fields)
      return if data.key?(:error)

      attributes = data[:attributes]
      included = data[:included] || {}

      video.source = url
      video.title = attributes[:title] if attributes[:title]
      video.description = attributes[:description][:bbc] if attributes[:description]
      video.save

      if included[:uploader]
        artist_tag = Tag.sanitize_name(included[:uploader][:name])
        if artist_tag.present?
          artist_tag = video.add_tag('artist:' + artist_tag)
          TagHistory.record_tag_changes(artist_tag[0], artist_tag[1], video.id) if !artist_tag.nil?
        end
      end
    end
  end
end
