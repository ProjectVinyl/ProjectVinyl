class ArtistController < ApplicationController
  def view
    if @user = User.where(id: params[:id].split(/-/)[0]).first
      @videos = user_signed_in? && current_user.id == @user.id ? @user.videos : @user.videos.where(hidden: false)
      @videos = Pagination.paginate(@videos, 0, 8, true)
      @videos_count = @videos.count
      @albums = Pagination.paginate(@user.albums, 0, 8, true)
      @albums_count = @albums.count
      @modificationsAllowed = user_signed_in? && (current_user.id == @user.id || current_user.is_admin)
      @featured = @user.albums.where('featured > 0').order(:featured).reverse_order
    end
  end
  
  def update
    input = params[:user]
    if user_signed_in?
      if current_user.is_admin && params[:user_id]
        user = User.where(id: params[:user_id]).first
      elsif
        user = current_user
      end
      if user
        user.set_name(input[:username])
        user.description = ApplicationHelper.demotify(input[:description])
        user.bio = ApplicationHelper.demotify(input[:bio])
        user.setTags(input[:tag_string])
        user.save
        if current_user.is_admin && params[:user_id]
          redirect_to action: "view", id: user.id
        else
          redirect_to action: "edit", controller: "devise/registrations"
        end
        return
      end
    end
    render 'layouts/error', locals: { title: 'Access Denied', description: "You can't do that right now." }
  end
  
  def setbanner
    if user_signed_in?
      if current_user.is_admin && params[:user_id]
        user = User.where(id: params[:user_id]).first
      elsif
        user = current_user
      end
      if user
        user.setBanner(params[:erase] ? false : params[:user][:banner])
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
      if current_user.is_admin && params[:user_id]
        user = User.where(id: params[:user_id]).first
      elsif
        user = current_user
      end
      if user
        user.setAvatar(input[:avatar])
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
    if user = User.where(id: params[:id]).first
      render partial: '/layouts/artist_thumb_h', locals: {artist_thumb_h: user}
      return
    end
    render status: 404, nothing: true
  end
  
  def banner
    @user = current_user
    render partial: 'banner'
  end
end
