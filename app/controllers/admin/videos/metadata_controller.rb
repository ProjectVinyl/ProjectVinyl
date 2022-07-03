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
        return flash[:error] = meta[:error] if meta.key?(:error)
        return flash[:error] = "Video source was not found" if meta.empty?

        video.source = meta[:meta][:url]
        video.title = meta[:attributes][:title] if meta[:attributes][:title]
        video.description = meta[:attributes][:description][:bbc] if meta[:attributes][:description]

        add_artist_tag(video, meta[:included][:uploader]) if meta[:included][:uploader]

        TagHistory.record_source_changes(video)
        video.save

        Import::VideoThumbnailJob.perform_later(video.id, nil, meta[:id]) if params[:thumbnails]

        flash[:notice] = "The video was updated succesfully."
      end

      def add_artist_tag(video, uploader)
        artist_tag = Tag.sanitize_name(uploader[:name])
        return if !artist_tag.present?
        artist_tag = video.add_tag('artist:' + artist_tag)
        TagHistory.record_tag_changes(artist_tag[0], artist_tag[1], video.id) if !artist_tag.nil?
      end

      def include_hash(asked)
        data = {}
        [:title, :description, :tags].each do |key|
          data[key] = true if asked.include?(key)
        end

        data
      end

      def read_meta
        begin
          src = "https://www.youtube.com/watch?v=#{params[:source]}"

          fields = include_hash(params)
          fields[:artist] = params.include?(:tags)

          return ProjectVinyl::Web::Youtube.get(src, fields)
        rescue Exception => e
          return {error: "Unknown Error: #{e.message}"}
        end
      end
    end
  end
end
