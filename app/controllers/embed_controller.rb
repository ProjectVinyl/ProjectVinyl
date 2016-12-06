class EmbedController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  after_action :allow_embeds
  
  def view
    if @video = Video.where(id: params[:id]).first
      @user = @video.user
    end
    if @video && @video.duplicate_id > 0
      @video = Video.where(id: @video.duplicate_id).first
    end
    if @video && params[:list]
      if @album = Album.where(id: params[:list]).first
        @items = @album.all_items
        @index = params[:index].to_i || (@items.first ? @items.first.index : 0)
        if @index > 0
          @prev_video = @album.get_prev(current_user, @index)
        end
        @next_video = @album.get_next(current_user, @index)
      end
    end
  end
  
  def oembed
    if url = params[:url]
      url = url.split('?')
      url[0] = url[0].split('/').last.split('-')[0].to_i
      puts url[0]
      if (url.length > 1)
        extra = '?' + url[1]
      else
        extra = ''
      end
      @video = Video.where(id: url[0]).first
      if @video && @video.duplicate_id > 0
        @video = Video.where(id: @video.duplicate_id).first
      end
      if @video.hidden
        render status: 401, nothing: true
      end
      if @video
        width = 560
        if params[:maxwidth] && width > (mw = params[:maxwidth].to_i)
          width = mw
        end
        height = 315
        if params[:maxheight] && height > (mw = params[:maxheight].to_i)
          height = mw
        end
        @result = {
          provider_url: 'http://www.projectvinyl.net/',
          author_name: @video.user.username,
          thumbnail_url: 'http://www.projectvinyl.net/cover/' + @video.id.to_s + '.png',
          type: 'video',
          author_url: 'https://www.projectvinyl.net/profile/' + @video.user.username,
          provider_name: 'Project Vinyl',
          version: '1.0',
          thumbnail_width: width,
          thumbnail_height: height,
          html: '<iframe width="' + width.to_s + '" height="' + height.to_s + '" src="http://www.projectvinyl.net/embed/' + @video.id.to_s + extra + '" frameborder="0" allowfullscreen></iframe>',
          width: width,
          height: height,
          title: @video.title
        }
        if params[:format] == 'xml'
          return render xml: @result, root: 'oembed'
        end
        return render json: @result
      end
    end
    render status: 404, nothing: true
  end
  
  private
  def allow_embeds
    response.headers.except! 'X-Frame-Options'
  end
end