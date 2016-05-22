class ArtistController < ApplicationController
  def view
    @artist = Artist.find(params[:id].split(/-/)[0])
    @videos = @artist.videos
    @albums = @artist.albums
  end
end
