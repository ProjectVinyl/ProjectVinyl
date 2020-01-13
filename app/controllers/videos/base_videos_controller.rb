module Videos
  class BaseVideosController < ApplicationController
    protected
    def check_then
      if !user_signed_in?
        return head :unauthorized
      end

      if !(video = Video.where(id: params[:video_id]).first)
        return head :not_found
      end

      yield(video)
    end

    def by_type
      if user_signed_in? && current_user.is_contributor?
        if params[:merged]
          @data = 'merged=1'
          return yield(true, Video.where.not(duplicate_id: 0))
        elsif params[:unlisted]
          @data = 'unlisted=1'
          return yield(true, Video.where(hidden: true))
        elsif params[:unprocessed]
          @data = 'unprocessed=1'
          return yield(true, Video.where(processed: nil))
        end
      end

      yield(false, Video.finder)
    end

    def load_album
      if params[:list] || params[:q]
        if params[:q]
          @album = VirtualAlbum.new(params[:q], @video, params[:index].to_i)
          @video = @album.current(@video)
        else
          @album = Album.where(id: params[:list]).first
        end

        if @album
          @items = params[:q] ? @album.album_items : @album.album_items.order(:index)
          @index = params[:index].to_i || (@items.first ? @items.first.index : 0)
          @index = @album.current_index(@index)

          if @index > 0
            @prev_video = @album.get_prev(current_user, @index)
          end

          @next_video = @album.get_next(current_user, @index)

          @album_editable = user_signed_in? && @album.owned_by(current_user)
        end
      end
    end
  end
end
