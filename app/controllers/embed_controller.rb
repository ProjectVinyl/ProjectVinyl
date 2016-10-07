class EmbedController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  def view
    if @video = Video.where(id: params[:id].split(/-/)[0]).first
      @user = @video.user
    end
    if @video.duplicate_id > 0
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
end