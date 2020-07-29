module Forum
  class SubscribeController < ApplicationController
    def update
      return head 401 if !user_signed_in? || !(thread = CommentThread.where(id: params[:thread_id]).first)
      render json: {
        added: thread.toggle_subscribe(current_user)
      }
    end
  end
end
