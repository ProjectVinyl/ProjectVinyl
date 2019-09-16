module Admin
  module Videos
    class MetadataController < BaseVideosAdminController
      def update
        try_to do |video|
          result = video.pull_meta(params[:source], params)

          if result == :ok
            flash[:notice] = "The video was updated succesfully."
          elsif result == :not_found
            flash[:error] = "Video source was not found."
          else
            flash[:error] = "Error #{result}."
          end
        end
      end
    end
  end
end
