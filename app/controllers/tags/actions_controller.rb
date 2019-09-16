module Tags
  class ActionsController < ApplicationController
    def hide
      toggle_action {|subscription| subscription.toggle_hidden }
    end

    def spoiler
      toggle_action {|subscription| subscription.toggle_spoilered }
    end

    def watch
      toggle_action {|subscription| subscription.toggle_watched }
    end
    
    private
    def toggle_action
      if !user_signed_in?
        return head 401
      end
      
      if params[:tag_id].to_i.to_s != params[:tag_id]
        params[:tag_id] = Tag.where(name: params[:tag_id]).first.id
      end
      if !(subscription = TagSubscription.where(user_id: current_user.id, tag_id: params[:tag_id]).first)
        subscription = TagSubscription.new(
          user_id: current_user.id,
          tag_id: params[:tag_id],
          hide: false,
          spoiler: false,
          watch: false
        )
      end
      yield(subscription)
      render json: {
        hide: subscription.hide,
        spoiler: subscription.spoiler,
        watch: subscription.watch
      }
    end
  end
end
