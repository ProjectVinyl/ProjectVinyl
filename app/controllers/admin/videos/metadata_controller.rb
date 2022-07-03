module Admin
  module Videos
    class MetadataController < BaseVideosAdminController
      def update
        try_to do |video|
          return flash[:error] = "No source provided." if params[:source].blank?

          fields = include_hash(params)
          fields[:artist] = params.include?(:tags)

          Import::SelectiveVideoAttributesJob.perform_later(video.id, params[:source], fields)
          Import::VideoThumbnailJob.perform_later(video.id, nil, params[:source]) if params[:thumbnails]

          flash[:notice] = "The video will be updated shortly."
        end
      end

      private
      def include_hash(asked)
        data = {}
        [:title, :description, :tags].each do |key|
          data[key] = true if asked.include?(key)
        end

        data
      end
    end
  end
end
