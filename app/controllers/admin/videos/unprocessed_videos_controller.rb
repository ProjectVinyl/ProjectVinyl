module Admin
  module Videos
    class UnprocessedVideosController < BaseVideosAdminController
      def index
        page(Video.where("(processed IS NULL or processed = false) AND hidden = false"), true)
      end

      def update
        try_to do |video|
          flash[:notice] = Encode::VideoJob.queue_video(video, :manual)
        end
      end
    end
  end
end
