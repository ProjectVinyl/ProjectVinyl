module Videos
  class FeedsController < ApplicationController
    def show
      return redirect_to action: "index", controller: "welcome" if !user_signed_in?

      current_user.feed_count = 0
      current_user.save

      @records = TagSubscription.get_feed_items(current_user, current_filter)

      return render_pagination partial_for_type(:videos), @results, params[:page].to_i, 30, false if params[:format] == 'json'
      render_listing_partial @records, params[:page].to_i, 30, false, {
        partial: partial_for_type(:videos),
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

      entries = make_entries(Tag.split_to_ids(params[:user][:watched_tag_string]))

      current_user.tag_subscriptions.destroy_all
      current_user.tag_subscriptions.create entries
    end

    private
    def make_entries(entries)
      entries.map do |i|
        { tag_id: i, hide: false, spoiler: false, watch: true }
      end
    end
  end
end