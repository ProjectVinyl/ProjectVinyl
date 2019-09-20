module Tags
  class ActionsController < ApplicationController
    def update
      toggle_action do |subscription|
        if params[:id] == 'hide'
          subscription.toggle_hidden
        elsif params[:id] == 'spoiler'
          subscription.toggle_spoilered
        elsif params[:id] == 'watch'
          subscription.toggle_watched
        end
      end
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
