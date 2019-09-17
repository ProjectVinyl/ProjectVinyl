module Admin
  module Videos
    class ThumbnailsController < BaseVideosAdminController

      def update

        redirect_to action: :view, controller: '/admin/admin'

        if !current_user.is_contributor?
          flash[:notice] = "Access Denied: You do not have the required permissions."
          return
        end

        begin
          Video.all.pluck(:id).find_each(batch_size: 500) do |id|
            RethumbThumbJob.perform_later(id)
          end
          flash[:notice] = "All thumbnails have been queue for a refresh"
        rescue Exception => e
          flash[:error] = "Error: Could not schedule action."
        end
      end

      def destroy
        try_to do |video|
          video.set_thumbnail
          flash[:notice] = "Thumbnail Reset."
        end
      end
    end
  end
end
