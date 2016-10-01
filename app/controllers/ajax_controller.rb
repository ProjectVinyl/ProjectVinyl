class AjaxController < ApplicationController
  def notifications
    if user_signed_in?
      if current_user.notification_count != params[:notes].to_i || current_user.feed_count != params[:feeds].to_i
        return render json: {
          notices: current_user.notification_count,
          feeds: current_user.feed_count
        }
      else
        return render status: 204, nothing: true
      end
    end
    render status: 401, nothing: true
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
    if user_signed_in?
      if (album = Album.where(id: params[:item]).first) && album.ownedBy(current_user)
        if video = Video.where(id: params[:id]).first
          render json: { :added => album.toggle(video) }
          return
        end
      end
    end
    render status: 401, nothing: true
  end
  
  def togglePin
    if user_signed_in? && current_user.is_staff?
      if thread = CommentThread.where(id: params[:id]).first
        thread.pinned = !thread.pinned
        thread.save
        render json: { :added => thread.pinned }
        return
      end
    end
    render status: 401, nothing: true
  end
  
  def toggleLock
    if user_signed_in? && current_user.is_contributor?
      if thread = CommentThread.where(id: params[:id]).first
        thread.locked = !thread.locked
        thread.save
        render json: { :added => thread.locked }
        return
      end
    end
    render status: 401, nothing: true
  end
  
  def toggleFeature
    if user_signed_in? && current_user.is_staff?
      if video = Video.where(id: params[:id]).first
        Video.where(featured: true).update_all(featured: false)
        video.featured = !video.featured
        video.save
        render json: { :added => video.featured }
        return
      end
    end
    render status: 401, nothing: true
  end
end
