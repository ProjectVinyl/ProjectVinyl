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

    begin
      mode = :wilson

      if mode == :wilson
        @popular = current_filter.videos.where(hidden: false, listing: 0, duplicate_id: 0)
            .order(:wilson_lower_bound)
            .reverse_order
            .limit(4)
            .records
            .for_thumbnails(current_user)
      else
        popular_ids = cache("welcome_popular", expires_in: 1.minute) do
          current_filter.videos.where(hidden: false, listing: 0, duplicate_id: 0)
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
                  .limit(4)
                  .ids
        end
        @popular = Video.where('videos.id IN (?)', popular_ids).for_thumbnails(current_user)
      end
    rescue Elasticsearch::Transport::Transport::Errors::InternalServerError => e
      @exception_flag = true
      @popular = current_filter.videos.where(hidden: false, listing: 0, duplicate_id: 0)
                .order(:heat, :updated_at, :created_at)
                .reverse_order
                .limit(4)
                .records
                .for_thumbnails(current_user)
    end

    @featured = current_filter.videos.where(hidden: false, listing: 0, duplicate_id: 0)
              .where(featured: true)
              .limit(1)
              .records
              .for_thumbnails(current_user)
              .first
    @feed = TagSubscription.get_feed_items(current_user, current_filter).limit(15) if user_signed_in?
  end
end
