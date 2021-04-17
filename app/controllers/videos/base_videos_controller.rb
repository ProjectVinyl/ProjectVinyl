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
          @album = Albums::VirtualAlbum.new(params[:q], @video, params[:index].to_i, current_filter)
          @video = @album.current(@video)
        else
          @album = Album.where(id: params[:list]).first
        end

        if @album
          @items = params[:q] ? @album.album_items : @album.album_items.order(:index)
          @index = params[:index].to_i || (@items.first ? @items.first.index : 0)
          @index = @album.current_index(@index)

          @prev_video = @album.previous_video(current_filter, @index) if @index > 0
          @next_video = @album.next_video(current_filter, @index)

          @album_editable = user_signed_in? && @album.owned_by(current_user)
        end
      end
    end
  end
end
