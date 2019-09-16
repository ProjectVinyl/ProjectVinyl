module Forum
  class SubscribeController < ApplicationController
    def update
      if !user_signed_in? || !(thread = CommentThread.where(id: params[:thread_id]).first)
        head 401
      end
      
      return render json: {
        added: thread.toggle_subscribe(current_user)
      }
    end
  end
end
