class WelcomeController < ApplicationController
  def index
    @all = Video.Finder.order(:created_at).reverse_order.limit(50)
    @comments = Comment.Searchable.includes(:direct_user, :comment_thread).order(:created_at).reverse_order.limit(5)
    @popular = Video.Popular
    @featured = Video.Finder.where(featured: true).first
    @featured_album = Album.where('featured > 0').first
    if user_signed_in?
      @feed = TagSubscription.get_feed_items(current_user).limit(15)
    end
  end
end
