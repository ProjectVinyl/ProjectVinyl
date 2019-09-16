module Admin
  module Videos
    class MergedVideosController < BaseVideosAdminController
      def update
        try_to do |video|
          flash[:notice] = "Changes Saved."

          if params[:video] && other = Video.where(id: params[:video][:duplicate_id]).first
            return video.merge(current_user, other)
          end

          video.unmerge
        end
      end
    end
  end
end
