class AjaxController < ApplicationController
  def reporter
    render json: {
      content: render_to_string(partial: '/layouts/reporter', locals: { 'video': params[:id] })
    }
  end
  
  def upvote
    if user_signed_in?
      if video = Video.where(id: params[:id]).first
        render json: { :count => video.upvote(current_user, params[:incr]) }
        return
      end
    end
    render status: 401, nothing: true
  end
  
  def downvote
    if user_signed_in?
      if video = Video.where(id: params[:id]).first
        render json: { :count => video.downvote(current_user, params[:incr]) }
        return
      end
    end
    render status: 401, nothing: true
  end
  
  def star
    if user_signed_in?
      if video = Video.where(id: params[:id]).first
        render json: { :added => video.star(current_user) }
        return
      end
    end
    render status: 401, nothing: true
  end
  
  def toggleAlbum
    if user_signed_in? && current_user.artist_id
      if video = Video.where(id: params[:id]).first
        if video.artist_id == current_user.artist_id && album = Album.where(id: params[:item]).first
          if video.artist_id == album.owner_id && album.ownedBy(current_user)
            render json: { :added => album.toggle(video) }
            return
          end
        end
      end
    end
    render status: 401, nothing: true
  end
end
