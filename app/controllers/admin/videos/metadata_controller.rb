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
          src = "https://www.youtube.com/watch?v=#{ProjectVinyl::Web::Youtube.video_id(src)}"
          video.set_source(src)

          fields[:artist] = fields[:tags]
          meta = ProjectVinyl::Web::Youtube.get(src, fields)

          video.set_title(meta[:title]) if meta[:title]
          video.description = meta[:description][:bbc] if meta[:description]

          if meta[:artist]
            if (artist_tag = Tag.sanitize_name(meta[:artist][:name])) && !artist_tag.empty?
              artist_tag = Tag.add_tag('artist:' + artist_tag, video)

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
