class AlbumController < ApplicationController
  def view
    @album = Album.find(params[:id].split(/-/)[0])
    @items = @album.album_items.order(:index)
    @modificationsAllowed = session[:current_user_id] == @album.artist.id
  end
end
