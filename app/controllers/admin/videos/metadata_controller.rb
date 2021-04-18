module Admin
  module Videos
    class MetadataController < BaseVideosAdminController
      def update
        try_to{|video| pull_meta(video) }
      end

      private
      def pull_meta(video)
        return flash[:error] = "No source provided." if params[:source].blank?

        meta = read_meta

        return flash[:error] = "Video source was not found" if meta.empty?

        video.source = meta[:meta][:url]
        video.title = meta[:attributes][:title] if meta[:attributes][:title]
        video.description = meta[:attributes][:description][:bbc] if meta[:attributes][:description]

        add_artist_tag(video, meta[:included][:uploader]) if meta[:included][:uploader]

        TagHistory.record_source_changes(video)
        video.save

        flash[:notice] = "The video was updated succesfully."
      end

      def add_artist_tag(video, uploader)
        artist_tag = Tag.sanitize_name(uploader[:name])
        return if !artist_tag.present?
        artist_tag = video.add_tag('artist:' + artist_tag)
        TagHistory.record_tag_changes(artist_tag[0], artist_tag[1], video.id) if !artist_tag.nil?
      end

      def read_meta
        begin
          src = "https://www.youtube.com/watch?v=#{ProjectVinyl::Web::Youtube.video_id(params[:source])}"

          fields = params.permit(:title, :description, :tags)
          fields[:artist] = params[:tags]

          return ProjectVinyl::Web::Youtube.get(src, fields)
        rescue Error => e
          flash[:error] = "Unknown Error: #{e.message}"
        end

        {}
      end
    end
  end
end
