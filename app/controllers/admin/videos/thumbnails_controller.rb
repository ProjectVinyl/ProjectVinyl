module Admin
  module Videos
    class ThumbnailsController < BaseVideosAdminController

      def update
        redirect_to action: :index, controller: '/admin/admin'

        if !current_user.is_contributor?
          return flash[:notice] = "Access Denied: You do not have the required permissions."
        end

        flash[:notice] = CheckThumbnailJob.queue_videos(Video.all, :manual)
      end

      def destroy
        try_to do |video|
          flash[:notice] = ExtractThumbnailJob.queue_video(video, nil, nil, :manual)
        end
      end
    end
  end
end
