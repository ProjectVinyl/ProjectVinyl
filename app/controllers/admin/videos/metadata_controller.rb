module Admin
  module Videos
    class MetadataController < BaseVideosAdminController
      def update
        try_to do |video|
          pull_meta(video, params[:source], params)
        end
      end

      private
      def pull_meta(video, src, fields)
        if src.present?
          fields[:artist] = fields[:tags]

          src = "https://www.youtube.com/watch?v=#{ProjectVinyl::Web::Youtube.video_id(src)}"
          meta = ProjectVinyl::Web::Youtube.get(src, fields)

          video.source = src
          video.title = meta[:title] if meta[:title]
          video.description = meta[:description][:bbc] if meta[:description]

          if meta[:artist]
            if (artist_tag = Tag.sanitize_name(meta[:artist][:name])) && !artist_tag.empty?
              artist_tag = video.add_tag('artist:' + artist_tag)

              if !artist_tag.nil?
                TagHistory.record_tag_changes(artist_tag[0], artist_tag[1], video.id)
              end
            end
          end

          TagHistory.record_source_changes(video)
          video.save

          if meta.empty?
            flash[:error] = "Video source was not found."
            return
          end

          flash[:notice] = "The video was updated succesfully."
          return
        end

        flash[:error] = "Error #{result}."
      end
    end
  end
end
