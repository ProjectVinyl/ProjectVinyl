require 'projectvinyl/search/search'

class UsersController < Users::BaseUsersController
  include Searchable

  configure_ordering [:username, :created_at]

  def show
    check_details_then do |user, edits_allowed|
      @tags = @user.tags.includes(:tag_type)
      @modifications_allowed = edits_allowed

      if @user.tag_id
        @art = current_filter.videos.where(hidden: false, duplicate_id: 0, tags: [ @user.tag.name ])
        @art = @art.paginate(0, 8){|recs| recs.with_tags.with_likes(current_user) }
      end

      @videos = current_filter.videos.where(hidden: false, duplicate_id: 0, user_id: @user.id)
      @videos = @videos.where(listing: 0) if !edits_allowed
      @videos = @videos.reverse_order.paginate(0, 8)

      @watched = @user.watched_videos.unmerged
      @watched = @watched.listable if !edits_allowed

      @watched_count = @watched.count(:all)

      @watched = current_filter.videos.where(id: @watched.limit(8).map(&:id))
      @watched = @watched.reverse_order.paginate(0, 8) {|t| t.with_tags.with_likes(current_user)}

      @favourites = current_filter.videos.where(hidden: false, duplicate_id: 0, albums: [ @user.stars.id ])
      @favourites = @favourites.where(listing: 0) if !edits_allowed
      @favourites = @favourites.reverse_order.paginate(0, 8){|t| t.with_tags.with_likes(current_user)}

      @albums = @user.albums.where(hidden: false)
      @albums = @albums.where(listing: 0) if !edits_allowed
      @albums = Pagination.paginate(@albums.order(:created_at), 0, 8, true)
      @comments = Pagination.paginate(@user.comments.visible.decorated.with_likes(current_user).order(:created_at), 0, 3, true)
    end
  end

  def update
    check_then do |user|
      input = params[:user]

      user.tag = Tag.by_name_or_id(input[:tag]).first if current_user.is_contributor?
      user.set_name(input[:username])
      user.description = input[:description]
      user.bio = input[:bio]
      user.default_listing = (input[:default_listing] || 0).to_i
      user.set_tags(input[:tag_string])
      user.time_zone = input[:time_zone]
      user.save

      if (params[:video][:apply_to_all] == '1')
        Video.where(user_id: user).update_all(listing: user.default_listing)
      end

      return redirect_to action: :edit, controller: "users/registrations" if user.id == current_user.id
      redirect_to action: :show, controller: "admin/users"
    end
  end

  def index
    read_search_params params
    if filtered?
      @records = ProjectVinyl::Search::ActiveRecord.new(User)
        .must(ProjectVinyl::Search.interpret(@query, ProjectVinyl::Search::USER_INDEX_PARAMS, current_user).to_hash)
        .order(order_field)
      @records = @records.reverse_order if !@ascending
      @records = @records.paginate(@page, 50)
    else
      @records = Pagination.paginate(User.all.order(order_field), @page, 50, !@ascending)
    end

    render_paginated @records, {
      template: 'pagination/search', table: 'users', label: 'User'
    }
  end
end