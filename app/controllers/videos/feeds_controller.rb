module Videos
  class FeedsController < ApplicationController
    def show
      if !user_signed_in?
        return redirect_to action: "index", controller: "welcome"
      end

      current_user.feed_count = 0
      current_user.save

      @records = TagSubscription.get_feed_items(current_user)

      if params[:format] == 'json'
        return render_pagination 'videos/thumb_h', @results, params[:page].to_i, 30, false
      end

      render_listing_partial @records, params[:page].to_i, 30, false, {
        partial: 'videos/thumb_h', type: :videos, table: :feed, label: 'Feed'
      }
    end

    def edit
      if !user_signed_in?
        redirect_to action: :index, controller: :welcome
      end
    end

    def update
      if !user_signed_in?
        return redirect_to action: "edit"
      end

      hidden = Tag.get_tag_ids(Tag.split_tag_string(params[:user][:hidden_tag_string]))

      spoilered = Tag.get_tag_ids(Tag.split_tag_string(params[:user][:spoilered_tag_string]))

      watched = Tag.get_tag_ids(Tag.split_tag_string(params[:user][:watched_tag_string]))

      hidden -= watched
      spoilered -= hidden

      combined = (hidden | spoilered | watched).uniq

      existing = current_user.tag_subscriptions.pluck(:tag_id)

      lost = existing - combined

      if !lost.empty?
        TagSubscription.where('user_id = ? AND tag_id IN (?)', current_user.id, lost).destroy_all
      end

      gained = combined - existing

      if !gained.empty?
        gained = gained.map do |i|
          { user_id: current_user.id, tag_id: i, hide: false, spoiler: false, watch: false }
        end
        TagSubscription.create(gained)
      end

      TagSubscription.where('user_id = ?', current_user.id).update_all('hide = false, watch = false, spoiler = false')

      if !hidden.empty?
        TagSubscription.where('user_id = ? AND tag_id IN (?)', current_user.id, hidden).update_all('hide = true')
      end

      if !spoilered.empty?
        TagSubscription.where('user_id = ? AND tag_id IN (?)', current_user.id, spoilered).update_all('spoiler = true')
      end

      if !watched.empty?
        TagSubscription.where('user_id = ? AND tag_id IN (?)', current_user.id, watched).update_all('watch = true')
      end
    end
  end
end