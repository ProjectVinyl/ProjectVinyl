require 'projectvinyl/elasticsearch/index'
require 'projectvinyl/elasticsearch/elastic_selector'

class UsersController < Users::BaseUsersController
  include Searchable
  
  configure_ordering [:username, :created_at]

  def show
    check_details_then do |user, edits_allowed|
      @tags = @user.tags.includes(:tag_type)
      @modifications_allowed = edits_allowed

      @art = Pagination.paginate(@user.tag.videos.listable.with_likes(current_user), 0, 8, true) if @user.tag_id

      @videos = edits_allowed ? @user.videos.unmerged : @user.videos.listable
      @videos = Pagination.paginate(@videos.order(:created_at).with_tags.with_likes(current_user), 0, 8, true)

      @watched = edits_allowed ? @user.watched_videos.unmerged : @user.watched_videos.listable
      @watched = Pagination.paginate(@watched.with_tags.with_likes(current_user), 0, 8, true)

      @albums = edits_allowed ? @user.albums : @user.albums.where(hidden: false, listing: 0)
      @albums = Pagination.paginate(@albums.order(:created_at), 0, 8, true)
      @comments = Pagination.paginate(@user.comments.visible.decorated.with_likes(current_user).order(:created_at), 0, 3, true)
    end
  end

  def update
    check_then do |user|
      input = params[:user]

      if current_user.is_contributor?
        user.tag = Tag.by_name_or_id(input[:tag]).first
      end
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

      if user.id == current_user.id
        return redirect_to action: :edit, controller: "users/registrations"
      end
      redirect_to action: :show, controller: "admin/users"
    end
  end
  
  def index
    read_search_params params
    
    if filtered?
      @results = ProjectVinyl::ElasticSearch::ElasticSelector.new(current_user, @query, ProjectVinyl::ElasticSearch::Index::USER_INDEX_PARAMS)
      @records = @results.order_by(order_field).query(@page, 50).exec
    else
      @records = Pagination.paginate(User.all.order(order_field), @page, 50, !@ascending)
    end

    render_paginated @records, {
      template: 'pagination/search', table: 'users', label: 'User'
    }
  end
end