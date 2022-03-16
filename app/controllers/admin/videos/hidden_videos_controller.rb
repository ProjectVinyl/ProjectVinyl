module Admin
  module Videos
    class HiddenVideosController < BaseVideosAdminController
      def index
        page(Video.where(hidden: true), true)
      end

      def destroy
        check_access_then do
          len = Video.where(hidden: true).count
          Video.where(hidden: true).destroy
          flash[:notice] = "#{len} item(s) deleted successfully."
        end
      end

      def update
        check_then do |video|
          video.hidden = !video.hidden
          video.save

          render json: {
            added: video.hidden
          }
        end
      end
    end
  end
end
