module Admin
  module Videos
    class ListingVideosController < BaseVideosAdminController
      def update
        try_to do |video|
          video.listing = params[:video][:listing].to_i
          video.save
        end
      end
    end
  end
end
