module Admin
  module Videos
    class RequeueVideosController < BaseVideosAdminController
      def update
        check_access_then do
          # flash[:notice] = "#{Verification::VideoVerification.rebuild_queue} videos in queue."
          Video.in_batches do |relation|
            relation.pluck(:id).each{|id| EncodeFilesJob.perform_later(id) }
          end
          flash[:notice] = "All videos will be processed again to generate missing media components"
        end
      end
    end
  end
end
