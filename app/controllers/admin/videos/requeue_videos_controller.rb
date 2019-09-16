module Admin
  module Videos
    class RequeueideosController < BaseVideosAdminController
      def update
        check_access_then do
          flash[:notice] = "#{Verification::Video.rebuild_queue} videos in queue."
        end
      end
    end
  end
end
