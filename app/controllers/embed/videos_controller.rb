module Embed
  class VideosController < Embed::EmbedController
    def show
      if params[:list] && (@album = Album.where(id: params[:list]).first)
        @items = @album.all_items
        @index = params[:index].to_i || (@items.first ? @items.first.index : 0)
        @video = @items.where(index: @index).first.video

        @prev_video = @album.get_prev(current_user, @index) if @index > 0
        @next_video = @album.get_next(current_user, @index)
      end

      @video = Video.where(id: params[:id]).first if !@video
      @video = Video.where(id: @video.duplicate_id).first if @video && @video.duplicate_id > 0
      @user = @video.user if @video
    end
  end
end
