module Admin
  module Videos
    class ThumbnailsController < BaseVideosAdminController
      def destroy
        try_to do |video|
          video.set_thumbnail
          flash[:notice] = "Thumbnail Reset."
        end
      end
    end
  end
end
