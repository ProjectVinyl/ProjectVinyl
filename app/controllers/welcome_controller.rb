class WelcomeController < ApplicationController
  def index
    @comments = Comment.with_threads("Video").order(:created_at).reverse_order.limit(5)
    @threads = Comment.with_threads("Board").order(:created_at).reverse_order.limit(5)
    @featured_album = Album.where('featured > 0').first

    @all = cache_videos(current_filter.videos.where(hidden: false, listing: 0, duplicate_id: 0)
              .order(:created_at)
              .reverse_order
              .limit(90), 'welcome_all').for_thumbnails(current_user)

    @active = cache_videos(current_filter.videos.where(hidden: false, listing: 0, duplicate_id: 0)
              .order(:boosted)
              .filter({
                range: {
                  updated_at: { gt: DateTime.now - 3.days }
                }
              })
              .reverse_order
              .limit(6), 'welcome_active').for_thumbnails(current_user)

    mode = :painless

    if mode == :wilson
      @popular = current_filter.videos.where(hidden: false, listing: 0, duplicate_id: 0)
          .order(:wilson_lower_bound)
          .reverse_order
          .limit(4)
          .records
          .for_thumbnails(current_user)
    else
      @popular = cache_videos(current_filter.videos.where(hidden: false, listing: 0, duplicate_id: 0)
                  .sort({
                    _script: {
                      type: :number,
                      script: {
                        lang: :painless,
                        source: "doc['heat'].value / (1 + params.now - doc['boosted'].value)",
                        params: {
                          now: DateTime.now.to_f / 1.day
                        }
                      },
                      order: :desc
                    }
                  })
                  .limit(6), "welcome_popular").for_thumbnails(current_user)
    end

    @featured = current_filter.videos.where(hidden: false, duplicate_id: 0)
              .must({
                bool: {
                  should: [
                    { term: { featured: true } },
                    { term: { tags: 'featured video' } }
                  ]
                }
              })
              .order(:featured)
              .reverse_order
              .limit(1)
              .records
              .for_thumbnails(current_user)
              .first
    @feed = TagSubscription.get_feed_items(current_user, current_filter).limit(15) if user_signed_in?
  end
end
