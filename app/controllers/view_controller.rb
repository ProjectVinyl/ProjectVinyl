class ViewController < ApplicationController
  def view
    @video = Video.find(params[:id].split(/-/)[0])
    @artist = Artist.find(@video.artist_id)
  end
end
