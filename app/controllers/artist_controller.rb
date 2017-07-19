class ArtistController < ApplicationController
  def view
    if !(@user = User.where(id: params[:id]).first)
      return render '/layouts/error', locals: { title: 'Nothing to see here!', description: 'If there was an artist here they\'re probably gone now. ... sorry.' }
    end
    
    @tags = @user.tags.includes(:tag_type)
    if @user.tag_id
      @art = @user.tag.videos.listable
      @art_count = @art.count
      @art = Pagination.paginate(@art, 0, 8, true)
    end
    @modifications_allowed = user_signed_in? && (current_user.id == @user.id || current_user.is_staff?)
    @videos = @modifications_allowed ? @user.videos.includes(:tags).where(duplicate_id: 0) : @user.videos.listable
    @videos = Pagination.paginate(@videos, 0, 8, true)
    @albums = @modifications_allowed ? @user.albums : @user.albums.where('`albums`.hidden = false AND `albums`.listing = 0')
    @albums = Pagination.paginate(@albums, 0, 8, true)
    @comments = Comment.finder.joins(:comment_thread).select('`comments`.*').where("`comments`.user_id = ? AND `comment_threads`.id = comment_thread_id AND NOT `comment_threads`.owner_type = 'Report' AND NOT `comment_threads`.owner_type = 'Pm'", @user.id).order(:created_at).reverse_order.limit(3)
  end
  
  def update
    input = params[:user]
    if user_signed_in?
      if current_user.is_contributor? && params[:user][:id]
        user = User.where(id: params[:user][:id]).first
      else
        user = current_user
      end
      if user
        if current_user.is_contributor?
          user.tag = Tag.by_name_or_id(input[:tag]).first
        end
        user.set_name(input[:username])
        user.set_description(input[:description])
        user.set_bio(input[:bio])
        user.set_tags(input[:tag_string])
        
        user.save
        if current_user.is_staff? && params[:user_id]
          redirect_to action: "view", id: user.id
        else
          redirect_to action: "edit", controller: "devise/registrations"
        end
        return
      end
    end
    render 'layouts/error', locals: { title: 'Access Denied', description: "You can't do that right now." }
  end
  
  def update_prefs
    current_user.prefs_cache.save(params[:settings]) if user_signed_in?
    redirect_to action: "edit", controller: "devise/registrations"
  end
  
  def setbanner
    if user_signed_in? && (current_user.is_staff? || current_user.id == params[:id])
      if current_user.id == params[:id]
        user = current_user
      elsif
        user = User.where(id: params[:id]).first
      end
      if user
        user.set_banner(params[:erase] ? false : params[:user][:banner])
        user.save
        if params[:async]
          render json: { result: "success" }
        else
          redirect_to action: "view", id: user.id
        end
        return
      end
    end
    render status: 401, nothing: true
  end
  
  def setavatar
    input = params[:user]
    if user_signed_in?
      if current_user.is_staff? && params[:user][:id]
        user = User.where(id: params[:user][:id]).first
      elsif
        user = current_user
      end
      if user
        user.set_avatar(params[:erase] ? false : input[:avatar])
        user.save
        if params[:async]
          render json: { result: "success" }
        else
          redirect_to action: "edit", controller: "devise/registrations"
        end
        return
      end
    end
    render 'layouts/error', locals: { title: 'Access Denied', description: "You can't do that right now." }
  end
  
  def card
    if user = User.with_badges.where(id: params[:id]).first
      return render partial: '/layouts/artist_thumb_h', locals: { artist_thumb_h: user }
    end
    render status: 404, nothing: true
  end

  def banner
    if current_user.is_staff? || current_user.id == params[:id]
      if current_user.id == params[:id]
        @user = current_user
      else
        @user = User.where(id: params[:id]).first
      end
      return render partial: 'banner'
    end
    render status: 404, nothing: true
  end
  
  def list
    @page = params[:page].to_i
    @results = Pagination.paginate(User.all.order(:created_at), @page, 50, true)
    render template: '/view/listing', locals: { type_id: 2, type: 'users', type_label: 'User', items: @results }
  end
  
  def page
    @page = params[:page].to_i
    @results = Pagination.paginate(User.all.order(:created_at), @page, 50, true)
    render json: {
      content: render_to_string(partial: 'layouts/artist_thumb_h', collection: @results.records),
      pages: @results.pages,
      page: @results.page
    }
  end
end