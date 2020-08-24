module Embed
  class VideosController < Embed::EmbedController
    def show
      if params[:list] && (@album = Album.where(id: params[:list]).first)
        @items = @album.album_items
        @index = params[:index].to_i || (@items.first ? @items.first.index : 0)
        @index = @album.current_index(@index)

        @video = @items.where(index: @index).first.video

        @prev_video = @album.previous_video(current_filter, @index) if @index > 0
        @next_video = @album.next_video(current_filter, @index)
      end

      @video = Video.where(id: params[:id]).first if !@video
      @video = Video.where(id: @video.duplicate_id).first if @video && @video.duplicate_id > 0
      @user = @video.user if @video
    end
  end
end
