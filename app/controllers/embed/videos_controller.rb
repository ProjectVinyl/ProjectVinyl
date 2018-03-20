module Embed
  class VideosController < Embed::EmbedController
    def view
      if params[:list]
        if @album = Album.where(id: params[:list]).first
          @items = @album.all_items
          @index = params[:index].to_i || (@items.first ? @items.first.index : 0)
          @video = @items.where(index: @index).first.video
          
          if @index > 0
            @prev_video = @album.get_prev(current_user, @index)
          end
          
          @next_video = @album.get_next(current_user, @index)
        end
      end
      
      if !@video
        @video = Video.where(id: params[:id]).first
      end
      
      if @video && @video.duplicate_id > 0
        @video = Video.where(id: @video.duplicate_id).first
      end
      
      if @video
        @user = @video.user
      end
    end
    
    def oembed
      if !(url = params[:url])
        head 404
      end
      
      url = url.split('?')
      url[0] = url[0].split('/')
      is_album = url[0][url[0].length - 2] == 'album'
      
      url[0] = url[0].last.split('-')[0].to_i
      
      if url.length > 1
        extra = '?' + url[1]
      else
        extra = ''
      end

      if is_album
        @album = Album.where(id: url[0]).first
        if @album && @item = @album.album_items.first
          @video = @item.video
        end
      else
        @video = Video.where(id: url[0]).first
      end
      
      if @video && @video.duplicate_id > 0
        @video = Video.where(id: @video.duplicate_id).first
      end
      
      if !@video
        head 404
      end
      
      if @video.hidden
        return head 401
      end
      
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
        thumbnail_url: "http://www.projectvinyl.net/cover/#{@video.id}.png",
        type: 'video',
        author_url: "https://www.projectvinyl.net/profile/#{@video.user.username}",
        provider_name: 'Project Vinyl',
        version: '1.0',
        thumbnail_width: width,
        thumbnail_height: height,
        html: "<iframe width=\"#{width.to_s}\" height=\"#{height.to_s}\" src=\"http://www.projectvinyl.net/embed/#{@video.id}#{extra}\" frameborder=\"0\" allowfullscreen></iframe>",
        width: width,
        height: height,
        title: @video.title
      }
      
      if params[:format] == 'xml'
        return render xml: @result, root: 'oembed'
      end
      
      render json: @result
    end
  end
end
