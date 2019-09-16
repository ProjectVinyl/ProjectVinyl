module Admin
  module Videos
    class ModerationsController < BaseVideosAdminController
      def update
        try_to do |video|
          video.moderation_note = params[:video][:moderation_note]
          video.save
        end
      end
    end
  end
end
