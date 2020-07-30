require 'projectvinyl/search/search'

class UsersController < Users::BaseUsersController
  include Searchable
  
  configure_ordering [:username, :created_at]

  def show
    check_details_then do |user, edits_allowed|
      @tags = @user.tags.includes(:tag_type)
      @modifications_allowed = edits_allowed

      @art = Pagination.paginate(@user.tag.videos.listable.with_likes(current_user), 0, 8, true) if @user.tag_id

      @videos = current_filter.videos.where(user_id: @user.id).where(duplicate_id: 0)
      @videos = @videos.where(hidden: false) if edits_allowed
      @videos = Pagination.paginate(@videos.records.with_tags.with_likes(current_user), 0, 8, true)

      @watched = @user.watched_videos.unmerged
      @watched = @watched.listable if edits_allowed
      @watched = Pagination.paginate(@watched.with_tags.with_likes(current_user), 0, 8, true)

      @albums = @user.albums
      @albums = @albums.where(hidden: false, listing: 0) if edits_allowed
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
      @results = ProjectVinyl::Search.paginate(current_user, @query, ProjectVinyl::Search::USER_INDEX_PARAMS)
      @records = @results.order_by(order_field).query(@page, 50).exec
    else
      @records = Pagination.paginate(User.all.order(order_field), @page, 50, !@ascending)
    end

    render_paginated @records, {
      template: 'pagination/search', table: 'users', label: 'User'
    }
  end
end