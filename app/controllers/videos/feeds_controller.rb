module Videos
  class FeedsController < ApplicationController
    def show
      return redirect_to action: "index", controller: "welcome" if !user_signed_in?

      current_user.feed_count = 0
      current_user.save

      @records = TagSubscription.get_feed_items(current_user)

      return render_pagination 'videos/thumb_h', @results, params[:page].to_i, 30, false if params[:format] == 'json'

      render_listing_partial @records, params[:page].to_i, 30, false, {
        partial: 'videos/thumb_h',
        type: :videos,
        table: :feed,
        label: 'Feed'
      }
    end

    def edit
      redirect_to action: :index, controller: :welcome if !user_signed_in?
    end

    def update
      return redirect_to action: "edit" if !user_signed_in?

      watched = Tag.get_tag_ids(Tag.split_tag_string(params[:user][:watched_tag_string]))
      hidden = Tag.get_tag_ids(Tag.split_tag_string(params[:user][:hidden_tag_string])) - watched
      spoilered = Tag.get_tag_ids(Tag.split_tag_string(params[:user][:spoilered_tag_string])) - hidden

      entries = make_entries(hidden, true, false, false)\
              | make_entries(spoilered, false, false, true)\
              | make_entries(watched, false, true, false)

      current_user.tag_subscriptions.destroy_all
      current_user.tag_subscriptions.create entries
    end

    private
    def make_entries(entries, hide, watch, spoiler)
      entries.map do |i|
        { tag_id: i, hide: hide, spoiler: spoiler, watch: watch }
      end
    end
  end
end