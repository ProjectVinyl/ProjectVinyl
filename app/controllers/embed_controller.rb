class EmbedController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  def view
    if @video = Video.where(id: params[:id].split(/-/)[0]).first
      @user = @video.user
    end
  end
end