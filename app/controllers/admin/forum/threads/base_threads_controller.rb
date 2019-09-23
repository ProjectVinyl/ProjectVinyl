module Admin
  module Forum
    module Threads
      class BaseThreadsController < BaseAdminController
        protected
        def toggle_action
          if !(thread = CommentThread.where(id: params[:thread_id]).first)
            return head :not_found
          end

          render json: {
            added: yield(thread)
          }
          thread.save
        end

        def check_permission
          if !user_signed_in? || !current_user.is_contributor?
            head 401
          end
        end
      end
    end
  end
end
