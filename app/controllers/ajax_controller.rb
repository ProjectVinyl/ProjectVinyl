class AjaxController < ApplicationController
  def notifications
    if user_signed_in?
      if params[:chat]
        result = {
          chats: []
        }
        if current_user.notification_count != params[:notes].to_i || current_user.feed_count != params[:feeds].to_i || current_user.message_count != params[:mail].to_i
          result[:notices] = current_user.notification_count
          result[:feeds] = current_user.feed_count
          result[:mail] = current_user.message_count
        end
        ids = []
        values = {}
        params[:chat].split(',').each do |t|
          t = t.split(':')
          ids << t[0]
          values[t[0].to_i] = t[1].to_i
        end
        CommentThread.where('id IN (?)', ids.uniq).each do |thread|
          last = thread.comments.last.id
          if last != values[thread.id]
            c = thread.comments.includes(:direct_user).order(:created_at).reverse_order.limit(50).reverse()
            result[:chats] << {
              id: thread.id,
              content: render_to_string(partial: 'thread/chat_message_set', locals: { thread: c }),
              last: last
            }
          end
        end
        return render json: result
      end
      if current_user.notification_count != params[:notes].to_i || current_user.feed_count != params[:feeds].to_i || current_user.message_count != params[:mail].to_i
        return render json: {
          notices: current_user.notification_count,
          feeds: current_user.feed_count,
          mail: current_user.message_count
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
          return render json: { :added => album.toggle(video) }
        end
      end
    end
    render status: 401, nothing: true
  end
  
  def toggleSubscribe
    if user_signed_in?
      if thread = CommentThread.where(id: params[:id]).first
        return render json: { :added => thread.toggleSubscribe(current_user)}
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
        if video.featured
          Tag.addTag('featured video', video)
        end
        video.save
        render json: { :added => video.featured }
        return
      end
    end
    render status: 401, nothing: true
  end
  
  def toggleAlbumFeature
    if user_signed_in? && current_user.is_staff?
      if album = Album.where(id: params[:id]).first
        Album.where('featured > 0').update_all(featured: 0)
        album.featured = album.featured > 0 ? 0 : 1
        album.save
        render json: { :added => album.featured > 0 }
        return
      end
    end
    render status: 401, nothing: true
  end
end
