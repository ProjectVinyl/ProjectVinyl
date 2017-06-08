class WelcomeController < ApplicationController
  def index
    @all = Video.finder.order(:created_at).reverse_order.limit(50)
    @comments = Comment.searchable.includes(:direct_user, :comment_thread).order(:created_at).reverse_order.limit(5)
    @popular = Video.popular
    @featured = Video.finder.where(featured: true).first
    @featured_album = Album.where('featured > 0').first
    if user_signed_in?
      @feed = TagSubscription.get_feed_items(current_user).limit(15)
    end
  end
end
