module Tags
  class ActionsController < ApplicationController
    ALLOWED_ACTIONS = [:hide, :spoiler, :watch]

    def update
      return head 401 if !user_signed_in?
      return head 401 if !ALLOWED_ACTIONS.include?(perform = params[:id].to_sym)
      return head 401 if perform != :watch && current_filter.user_id != current_user.id
      return head 404 if !(tag = Tag.by_name_or_id(params[:tag_id]).first)

      hide = current_filter.hides?(tag.id)
      spoiler = current_filter.spoilers?(tag.id)
      watch = current_user.tag_subscriptions.where(tag: tag).any?

      watch = !watch if perform == :watch
      spoiler = !spoiler if perform == :spoiler
      hide = !hide if perform == :hide

      hide = false if (perform == :watch && watch) || (perform == :spoiler && spoiler)
      spoiler, watch = [false,false] if hide

      current_filter.toggle_tag_flags!(tag, hide, spoiler)

      current_user.tag_subscriptions.where(tag: tag).destroy_all
      current_user.tag_subscriptions.create(tag: tag) if watch

      render json: { hide: hide, spoiler: spoiler, watch: watch }
    end
  end
end
