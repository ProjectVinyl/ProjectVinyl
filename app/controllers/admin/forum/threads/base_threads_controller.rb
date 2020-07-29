module Admin
  module Forum
    module Threads
      class BaseThreadsController < BaseAdminController
        protected
        def toggle_action
          return head :not_found if !(thread = CommentThread.where(id: params[:thread_id]).first)
          render json: {
            added: yield(thread)
          }
          thread.save
        end

        def check_permission
          head 401 if !user_signed_in? || !current_user.is_contributor?
        end
      end
    end
  end
end
