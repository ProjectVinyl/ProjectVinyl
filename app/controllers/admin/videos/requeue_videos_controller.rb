module Admin
  module Videos
    class RequeueVideosController < BaseVideosAdminController
      def update
        check_access_then do
          Video.in_batches do |relation|
            relation.pluck(:id).each{|id| Encode::VideoJob.perform_later(id) }
          end
          flash[:notice] = "All videos will be processed again to generate missing media components"
        end
      end
    end
  end
end
