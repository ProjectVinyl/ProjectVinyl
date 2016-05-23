class EmbedController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  def view
    @video = Video.find(params[:id].split(/-/)[0])
    @artist = @video.artist
    @queue = @artist.videos.where.not(id: @video.id).limit(5).order("RAND()")
  end
end