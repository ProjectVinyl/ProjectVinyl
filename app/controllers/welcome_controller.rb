class WelcomeController < ApplicationController
  def index
    @all = Video.finder.with_likes(current_user).order(:created_at).reverse_order.limit(50)
    @comments = Comment.visible.includes(:direct_user, :comment_thread).where("`comment_threads`.owner_type = 'Video'").order(:created_at).reverse_order.limit(5)
    @threads = Comment.visible.includes(:direct_user, :comment_thread).where("`comment_threads`.owner_type = 'Board'").order(:created_at).reverse_order.limit(5)
    @popular = Video.with_likes(current_user).popular
    @featured = Video.finder.with_likes(current_user).where(featured: true).first
    @featured_album = Album.where('featured > 0').first
    if user_signed_in?
      @feed = TagSubscription.get_feed_items(current_user).limit(15)
    end
  end
end
