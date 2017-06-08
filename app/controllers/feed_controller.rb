class FeedController < ApplicationController
  def view
    redirect_to action: "index", controller: "welcome" if !user_signed_in?
    current_user.feed_count = 0
    current_user.save
    @page = params[:page].to_i
    @videos = TagSubscription.get_feed_items(current_user)
    @videos = Pagination.paginate(@videos, @page, 30, false)
    render template: '/view/listing', locals: { type_id: 0, type: 'feed', type_label: 'Feed', items: @videos }
  end

  def edit
    redirect_to action: "index", controller: "welcome" if !user_signed_in?
  end

  def update
    if user_signed_in?
      hidden = Tag.split_tag_string(params[:user][:hidden_tag_string])
      hidden = Tag.get_tag_ids(hidden)
      spoilered = Tag.split_tag_string(params[:user][:spoilered_tag_string])
      spoilered = Tag.get_tag_ids(spoilered)
      watched = Tag.split_tag_string(params[:user][:watched_tag_string])
      watched = Tag.get_tag_ids(watched)
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
    redirect_to action: "edit"
  end

  def page
    @page = params[:page].to_i
    @results = TagSubscription.get_feed_items(current_user)
    @results = Pagination.paginate(@results, @page, 30, false)
    render json: {
      content: render_to_string(partial: '/layouts/video_thumb_h.html.erb', collection: @results.records),
      pages: @results.pages,
      page: @results.page
    }
  end
end
