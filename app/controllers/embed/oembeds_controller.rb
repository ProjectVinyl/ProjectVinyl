module Embed
  class OembedsController < Embed::EmbedController

    def show
      if !(url = params[:url])
        return head :not_found
      end

      url = url.split('?')
      url[0] = url[0].split('/')
      is_album = url[0][url[0].length - 2] == 'albums'

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
        return head :not_found
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
        provider_url: root_url,
        author_name: @video.user.username,
        thumbnail_url: absolute_url(@video.thumb),
        type: 'video',
        author_url: absolute_url(@video.user.link),
        provider_name: 'Project Vinyl',
        version: '1.0',
        thumbnail_width: width,
        thumbnail_height: height,
        html: "<iframe width=\"#{width.to_s}\" height=\"#{height.to_s}\" src=\"#{root_url}embed/#{@video.id}#{extra}\" frameborder=\"0\" allowfullscreen></iframe>",
        width: width,
        height: height,
        title: @video.title,
        tags: Tag.actualise(@video.tags.includes(:alias)).map {|a| a.get_as_string}
      }

      if params[:format] == 'xml'
        return render xml: @result, root: 'oembed'
      end

      render json: @result
    end
  end
end
