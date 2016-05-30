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
  
  def createvideo
    if user_signed_in?
      artist = Auth.current_author(session)
      video = artist.videos.create(title: nonnil(params[:title], 'Untitled'), description: nonnil(params[:descr], ''), upvotes: 0, downvotes: 0)
      render json: { video_id: video.id }
      return
    end
    render status: 401, nothing: true
  end
  
  def nonnil(param, defau)
    if param.nil? || param == ''
      return defau
    end
    return param
  end
end
