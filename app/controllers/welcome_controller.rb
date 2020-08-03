class WelcomeController < ApplicationController
  def index
    @comments = Comment.with_threads("Video").order(:created_at).reverse_order.limit(5)
    @threads = Comment.with_threads("Board").order(:created_at).reverse_order.limit(5)
    @featured_album = Album.where('featured > 0').first

    @all = current_filter.videos.where(hidden: false, listing: 0, duplicate_id: 0)
              .order(:created_at)
              .reverse_order
              .limit(90)
              .records
              .for_thumbnails(current_user)
    @popular = current_filter.videos.where(hidden: false, listing: 0, duplicate_id: 0)
              .order(:heat, :updated_at, :created_at)
              .reverse_order
              .limit(4)
              .records
              .for_thumbnails(current_user)
    @featured = current_filter.videos.where(hidden: false, listing: 0, duplicate_id: 0)
              .where(featured: true)
              .limit(1)
              .records
              .for_thumbnails(current_user)
              .first
    @feed = TagSubscription.get_feed_items(current_user, current_filter).limit(15) if user_signed_in?
  end
end
