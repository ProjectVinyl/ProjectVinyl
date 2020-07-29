module Tags
  class ActionsController < ApplicationController
    def update
      toggle_action do |subscription|
        subscription.toggle_hidden if params[:id] == 'hide'
        subscription.toggle_spoilered if params[:id] == 'spoiler'
        subscription.toggle_watched if params[:id] == 'watch'
      end
    end

    private
    def toggle_action
      return head 401 if !user_signed_in?

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
