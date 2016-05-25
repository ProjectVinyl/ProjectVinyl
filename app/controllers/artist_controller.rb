class ArtistController < ApplicationController
  def view
    if @artist = Artist.where(id: params[:id].split(/-/)[0]).first
      @videos = Pagination.paginate(@artist.videos, 0, 8, true)
      @albums = Pagination.paginate(@artist.albums, 0, 8, true)
    end
  end
end
