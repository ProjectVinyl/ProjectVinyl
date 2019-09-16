module Admin
  module Videos
    class BaseVideosAdminController < BaseAdminController

      protected
      def page(records, reverse)
        render_pagination 'admin/videos/thumb_h', records.with_likes(current_user), params[:page].to_i, 40, reverse
      end

      def check_then
        @id = params[:video_id] || params[:id]

        if !current_user.is_staff?
          return head :unauthorized
        end

        if !(video = Video.where(id: @id).first)
          return head :not_found
        end

        yield(video)
      end

      def check_access_then
        redirect_to action: :view, controller: 'admin/admin'

        if !current_user.is_contributor?
          return flash[:error] = "Error: Login required."
        end

        yield
      end

      def try_to
        @id = params[:video_id] || params[:id]
        redirect_to action: :show, controller: '/admin/videos', id: @id

        if !current_user.is_contributor?
          return flash[:error] = "Error: Login required."
        end

        if !(video = Video.where(id: @id).first)
          return flash[:error] = "Error: Video not found."
        end

        yield(video)
      end
    end
  end
end
