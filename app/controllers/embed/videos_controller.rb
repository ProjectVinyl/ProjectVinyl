module Embed
  class VideosController < Embed::EmbedController
    def show
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
  end
end
