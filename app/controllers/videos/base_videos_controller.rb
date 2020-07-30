module Videos
  class BaseVideosController < ApplicationController
    protected
    def check_then
      return head :unauthorized if !user_signed_in?
      return head :not_found if !(video = Video.where(id: params[:video_id]).first)
      yield(video)
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

          @prev_video = @album.get_prev(current_user, @index) if @index > 0
          @next_video = @album.get_next(current_user, @index)

          @album_editable = user_signed_in? && @album.owned_by(current_user)
        end
      end
    end
  end
end
