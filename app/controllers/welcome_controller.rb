class WelcomeController < ApplicationController
  def index
    @all = Video.Finder.order(:created_at).reverse_order.limit(50)
    @comments = Comment.joins(:comment_thread).where("`comments`.hidden = false AND `comment_threads`.owner_type != 'Report'").includes(:direct_user, :comment_thread).order(:created_at).reverse_order.limit(5)
    @popular = Video.Finder.where(created_at: (Date.today - 90)..Time.zone.now.end_of_day).where('views > ? OR score > ?', 0, 0).order(:score, :views, :updated_at, :created_at).reverse_order.limit(4)
    @featured = Video.where(featured: true, hidden: false).first
    @featured_album = Album.where('featured > 0').first
    if user_signed_in?
      @feed = TagSubscription.get_feed_items(current_user).limit(15)
    end
  end
end
