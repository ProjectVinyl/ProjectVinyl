module Admin
  module Videos
    class BaseVideosAdminController < BaseAdminController

      protected
      def page(records, reverse)
        render_pagination 'admin/videos/thumb_h', records.with_likes(current_user), params[:page].to_i, 40, reverse
      end

      def check_then
        @id = params[:video_id] || params[:id]

        return head :unauthorized if !current_user.is_staff?
        return head :not_found if !(video = Video.where(id: @id).first)
        yield(video)
      end

      def check_access_then
        redirect_to action: :index, controller: 'admin/admin'

        return flash[:error] = "Error: Login required." if !current_user.is_contributor?
        yield
      end

      def try_to
        @id = params[:video_id] || params[:id]
        redirect_to action: :show, controller: '/admin/videos', id: @id

        return flash[:error] = "Error: Login required." if !current_user.is_contributor?
        return flash[:error] = "Error: Video not found." if !(video = Video.where(id: @id).first)
        yield(video)
      end
    end
  end
end
