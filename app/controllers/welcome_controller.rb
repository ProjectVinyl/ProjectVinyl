class WelcomeController < ApplicationController
  def index
    @all = Video.listed.listable.with_tags.with_likes(current_user).order(:created_at).reverse_order.limit(90)
    @comments = Comment.with_threads("Video").order(:created_at).reverse_order.limit(5)
    @threads = Comment.with_threads("Board").order(:created_at).reverse_order.limit(5)
    @popular = Video.listed.listable.with_tags.with_likes(current_user).order(:heat).reverse_order.limit(4)
    @featured = Video.listed.listable.with_tags.with_likes(current_user).where(featured: true).first
    @featured_album = Album.where('featured > 0').first

    @feed = TagSubscription.get_feed_items(current_user).limit(15) if user_signed_in?
  end
end
