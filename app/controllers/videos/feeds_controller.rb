module Videos
  class FeedsController < ApplicationController
    include Searchable

    configure_ordering [ :date, :rating, [:wilson_score, :wilson_lower_bound], :heat, :length, :random, :relevance ],
      search_action: :search_index_path,
      only: [ :show ]

    def show
      return redirect_to action: "index", controller: "welcome" if !user_signed_in?

      current_user.feed_count = 0
      current_user.save

      @records = TagSubscription.feed_items(current_user, current_filter)
      @records = Pagination.paginate(@records, params[:page].to_i, 30, params[:order].to_i == 1)
      @watched_tags = current_user.watched_tags
      @watched_users = current_user.subscriptions

      render_paginated @records, {
        is_admin: false,
        resource: 'feed',
        table: 'videos',
        label: 'Video',
        template: 'videos/feeds/show'
      }
    end

    def edit
      redirect_to action: :index, controller: :welcome if !user_signed_in?
    end

    def update
      return redirect_to action: "edit" if !user_signed_in?

      current_user.tag_subscriptions.destroy_all
      current_user.tag_subscriptions.create(make_entries(Tag.split_to_ids(params[:user][:watched_tag_string])))
    end

    private
    def make_entries(entries)
      entries.map do |i|
        { tag_id: i }
      end
    end
  end
end