class UserController < ApplicationController
  def show
    check_details_then do |user, edits_allowed|
      @tags = @user.tags.includes(:tag_type)
      @modifications_allowed = edits_allowed
      
      if @user.tag_id
        @art = Pagination.paginate(@user.tag.videos.listable.with_likes(current_user), 0, 8, true)
      end
      
      @videos = edits_allowed ? @user.videos.includes(:tags).where(duplicate_id: 0) : @user.videos.listable
      @videos = Pagination.paginate(@videos.order(:created_at).with_likes(current_user), 0, 8, true)
      
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
      user.set_description(input[:description])
      user.set_bio(input[:bio])
      user.set_tags(input[:tag_string])
      user.save
      
      if current_user.is_staff? && params[:user_id]
        return redirect_to action: "view", id: user.id
      end
      
      redirect_to action: "edit", controller: "devise/registrations"
    end
  end
  
  def prefs
    if user_signed_in?
      current_user.prefs_cache.save(params[:settings])
    end
    redirect_to action: "edit", controller: "devise/registrations"
  end
  
  def set_banner
    check_then do |user|
      if params[:erase] || params[:user][:banner]
        user.set_banner(params[:erase] ? false : params[:user][:banner])
        user.save
      end
      
      if params[:format] == 'json'
        return render json: {
          result: "success"
        }
      end
      
      redirect_to action: "view", id: user.id
    end
  end
  
  def set_avatar
    check_then do |user|
      user.set_avatar(params[:erase] ? false : params[:user][:avatar])
      user.save
      
      if params[:format] == 'json'
        return render json: {
          result: "success"
        }
      end
      
      redirect_to action: "edit", controller: "devise/registrations"
    end
  end
  
  def hovercard
    if !(user = User.with_badges.where(id: params[:user_id]).first)
      return head :not_found
    end
    
    render partial: 'user/thumb_h', locals: {
      thumb_h: user
    }
  end

  def banner
    check_then do |user|
      @user = user
      render partial: 'banner'
    end
  end
  
  def index
    render_listing_total User.all.order(:created_at), params[:page].to_i, 50, true, {
      table: 'users', label: 'User'
    }
  end
  
  def uploads
    check_details_then do |user, edits_allowed|
      @records = user.videos.order(:created_at).includes(:tags).where(duplicate_id: 0)
      if !edits_allowed
        @records = @records.listable
      end
      
      @records = Pagination.paginate(@records, params[:page].to_i, 50, true)
      
      @label = 'Upload'
      @table = 'Video'
      @partial = partial_for_type(@table)
      
      if params[:format] == 'json'
        return render_pagination_json @partial, @records
      end
      render template: 'user/listing'
    end
  end
  
  def albums
    check_details_then do |user, edits_allowed|
      @records = user.albums.order(:created_at).where(hidden: false)
      if !edits_allowed
        @records = @records.where(listing: 0)
      end
      
      @records = Pagination.paginate(@records, params[:page].to_i, 50, true)
      
      @label = 'Album'
      @table = 'Album'
      @partial = partial_for_type(@table)
      
      if params[:format] == 'json'
        return render_pagination_json @partial, @records
      end
      
      @crumb = {
        stack: [
          { link: '/users', title: 'Users' },
          { link: @user.link, title: @user.username }
        ],
        title: "#{@label}s"
      }
      
      render template: 'user/listing'
    end
  end
  
  def comments
    check_details_then do |user, edits_allowed|
      @records = user.comments.visible.decorated.with_likes(current_user).order(:created_at)
      
      @records = Pagination.paginate(@records, params[:page].to_i, 50, true)
      
      @label = 'Comment'
      @table = 'Comment'
      @partial = partial_for_type(@table)
      
      if params[:format] == 'json'
        return render_pagination_json @partial, @records
      end
      
      @crumb = {
        stack: [
          { link: '/users', title: 'Users' },
          { link: @user.link, title: @user.username }
        ],
        title: @label.pluralize
      }
      
      render template: 'user/listing'
    end
  end
  
  private
  def check_details_then
    if !(@user = User.where(id: params[:id] || params[:user_id]).first)
      return render_error(
        title: 'Nothing to see here!',
        description: 'If there was someone here they\'re probably gone now. ... sorry.'
      )
    end
    
    yield(@user, user_signed_in? && (current_user.id == @user.id || current_user.is_staff?))
  end
  
  def check_then
    if !user_signed_in?
      return render_access_denied
    end
    
    id = params[:id] || params[:user_id]
    
    if id == current_user.id
      return yield(current_user)
    end
    
    if !current_user.is_staff?
      return render_access_denied
    end
    
    if !(user = User.where(id: id).first)
      return head :not_found
    end
    
    yield(user)
  end
end